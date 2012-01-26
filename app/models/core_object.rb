require "limelight"

class CoreObject
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Mentions
  include Limelight::Popularity

  cache

  # Denormilized:
  # Notification.object
  #TODO: bug: each core object type currently validates the length of content, but after creation content_raw is copied to content.
  field :title
  field :description
  field :content

  field :status, :default => 'active'
  field :favorites, :default => []
  field :favorites_count, :default => 0
  field :user_id
  field :response_count, :default => 0
  field :parent_type
  field :parent_id, :type => BSON::ObjectId
  field :tweet_id
  field :root_type
  field :root_id, :type => BSON::ObjectId

  auto_increment :public_id

  embeds_one :user_snippet, as: :user_assignable, :class_name => 'UserSnippet'
  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'
  embeds_many :likes, as: :user_assignable, :class_name => 'UserSnippet'

  belongs_to :user

  validates :user_id, :status, :presence => true
  validate :title_length, :content_length, :unique_source

  attr_accessible :title, :content, :parent_type, :parent_id, :source_name, :source_url, :source_video_id, :tweet_content, :tweet, :tweet_id
  attr_accessor :source_name, :source_url, :source_video_id, :tweet_content, :tweet

  default_scope where('status' => {'$ne' => 'disabled'})

  before_validation :set_source_snippet
  before_create :set_user_snippet, :current_user_own, :send_tweet, :set_root
  after_create :push_to_feeds, :neo4j_create, :update_response_count, :action_log_create
  after_update :expire_caches
  after_destroy :remove_from_feeds

  # hot damn lots of indexes. can we do this better? YES WE CAN
  # McM: chill out obama
  index :user_id
  index :favorites
  index :parent_id, sparse: true
  index :parent_type
  index :public_id, unique: true
  index :created_at
  index :ph
  index :pd
  index :pw
  index :pm
  index :pt
  index "topic_mentions._id"
  index "user_mentions._id"
  index "likes._id"
  index "sources.url"

  def to_param
    "#{encoded_id}-#{name.parameterize[0..40].chomp('-')}"
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  def set_source_snippet
    if @source_name || @source_url || @source_video_id
      source = SourceSnippet.new
      source.name = @source_name unless @source_name.blank?
      source.url = @source_url unless @source_url.blank?
      source.video_id = @source_video_id unless @source_video_id.blank?
      add_source(source)
    end
  end

  def add_source(source)
    found = sources.detect{|existing| existing.name && existing.name.to_url == source.name.to_url}
    unless found
      self.sources << source
    end
  end

  def expire_caches
    ['list', 'grid', 'column'].each do |view|
      ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}")
      ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-top-response") # talk list view includes response on feeds but not on show pages.
      ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-bottom-response") # talk list view includes response on feeds but not on show pages.
      ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-top")
      ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-bottom")
    end
  end

  # if required, checks that the given post URL is valid
  def has_valid_url
    if sources.length == 0
      errors.add(:url, "is required")
    end
    if sources.length > 0 && (sources[0].url.length < 3 || sources[0].url.length > 200)
      errors.add(:url, "must be between 3 and 200 characters long")
    end
  end

  def title_length
    if title_clean.length > 125
      errors.add(:title, "cannot be more than 125 characters long")
    end
  end

  def content_length
    if content_clean.length > 280
      errors.add(:content, "cannot be more than 280 characters long")
    end
  end

  def unique_source
    if sources.length > 0 && !self.persisted?
      if CoreObject.where('sources.url' => sources.first.url).first
        errors.add('Link', "has already been added to Limelight")
      end
    end
  end

  def send_tweet
    if @tweet == '1' && @tweet_content && !@tweet_content.blank? && user.twitter
      user.twitter.update(@tweet_content)
    end
  end

  # Favorites
  def favorited_by?(user_id)
    favorites.include? user_id
  end

  def add_to_favorites(user)
    if favorited_by? user.id
      false
    else
      self.favorites << user.id
      self.favorites_count += 1
      user.add_to_favorites(self)
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, 2)
      true
    end
  end

  def remove_from_favorites(user)
    if favorited_by? user.id
      self.favorites.delete(user.id)
      self.favorites_count -= 1
      user.remove_from_favorites(self)
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, -2)
      true
    else
      false
    end
  end

  # Likes
  def liked_by?(user_id)
    likes.where(:_id => user_id).first
  end

  def add_to_likes(user)
    like = liked_by? user.id
    if like
      false
    elsif (user_id == user.id)
      nil
    else
      like = self.likes.new(user.attributes)
      like.id = user.id
      user.likes_count += 1
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, 1)
      ActionLike.create(:action => 'create', :from_id => user.id, :to_id => id, :to_type => self.class.name)
      FeedItem.like(user, self)
      true
    end
  end

  def remove_from_likes(user)
    like = liked_by? user.id
    if like
      like.destroy
      user.likes_count -= 1
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, -1)
      ActionLike.create(:action => 'destroy', :from_id => user.id, :to_id => id, :to_type => self.class.name)
      FeedItem.unlike(user, self)
      true
    else
      false
    end
  end

  def update_response_count
    if parent_id
      CoreObject.collection.update(
        {:_id => parent_id},
        {
          "$inc" => { :response_count => 1 }
        }
      )
    end
  end

  def neo4j_create
    Resque.enqueue(Neo4jPostCreate, id.to_s)
  end

  def action_log_create
    ActionPost.create(:action => 'create', :from_id => user_snippet.id, :to_id => id, :to_type => self.class.name)
  end

  def action_log_delete
    ActionPost.create(:action => 'delete', :from_id => user_snippet.id, :to_id => id, :to_type => self.class.name)
  end

  def push_to_feeds
    FeedItem.post_create(self)
    #Resque.enqueue(FeedsPostCreate, id.to_s)
  end

  def set_root
    if parent_id
      self.root_id = parent_id
      self.root_type = parent_type
    elsif self.class.name == 'Talk' && primary_topic_mention
      self.root_id = primary_topic_mention
      self.root_type = 'Topic'
    else
      self.root_id = id
      self.root_type = _type
    end
  end

  def is_root?
    id == root_id
  end

  def disable
    self.status = 'disabled'
    FeedItem.post_disable(self, self.class.name == 'Talk' && !is_popular)
  end

  class << self
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end

    def for_show_page(parent_id)
      CoreObject.where(:parent_id => parent_id).order_by(:created_at, :desc)
    end

    # @example Fetch the core_objects for a feed with the given criteria
    #   CoreObject.feed
    #
    # @param [ display_types ] Array of CoreObject types to fetch for the feed
    # @param { order_by } Array of format { 'target' => 'field', 'order' => 'direction' } to sort the feed
    # @param { options } Options TODO: Fill out these options
    #
    # @return [ CoreObjects ]
    def feed(feed_id, feed_type, display_types, order_by, options)

      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedItem.where(:feed_id => feed_id, :feed_type => feed_type, :root_type => {'$in' => display_types})

      topic_ids = []
      item_ids = []
      items.each do |i|
        if i.root_type == 'Topic'
          topic_ids << i.root_id
        else
          item_ids << i.root_id
        end
        item_ids += i.responses if i.responses
      end

      topics = topic_ids.length > 0 ? Topic.where(:_id => {'$in' => topic_ids}) : []
      objects = CoreObject.where(:_id => {'$in' => item_ids})

      return_objects = []
      items.each do |i|
        if i.root_type == 'Topic'
          root = topics.detect{|t| t.id == i.root_id}
        else
          root = objects.detect{|o| o.id == i.root_id}
        end

        responses = objects.select{|o| i.responses && i.responses.include?(o.id)}
        return_objects << {:root => root, :responses => responses}
      end

      return_objects

      #or_criteria = []
      #or_criteria << {:_id.in => options[:includes_ids]} if options[:includes_ids]
      #or_criteria << {:user_id.in => options[:created_by_users]} if options[:created_by_users] && !options[:created_by_users].empty?
      #or_criteria << {"likes._id" => {"$in" => options[:liked_by_users]}} if options[:liked_by_users] && !options[:liked_by_users].empty?
      #or_criteria << {"topic_mentions._id" => {"$in" => options[:mentions_topics]}} if options[:mentions_topics] && !options[:mentions_topics].empty?
      #or_criteria << {"user_mentions._id" => {"$in" => options[:mentions_users]}} if options[:mentions_users] && !options[:mentions_users].empty?
      #or_criteria << {"parent_id" => options[:parent_id]} if options[:parent_id]
      #
      ##page length also hard-coded in views/core_object
      #page_length = options[:limit]? options[:limit] - 1 : 20
      #page_number = options[:page]? options[:page] : 1
      #num_to_skip = page_length * (page_number - 1)
      #
      #core_objects = self.only(:id, :_type, :parent_type, :parent_id)
      #
      ## page_length + 1 is used below so that one extra object is returned, allowing the views to check if there are more objects
      #if or_criteria.length > 0
      #  core_objects = core_objects.where(:status => "active", :parent_type => {'$in' => display_types}).any_of(or_criteria).skip(num_to_skip).limit(page_length + 1)
      #else
      #  core_objects = core_objects.where(:status => "active", :parent_type => {'$in' => display_types}).skip(num_to_skip).limit(page_length + 1)
      #end
      #
      ## if we are exluding some parent ids
      #if options[:not_parent_ids]
      #  core_objects = core_objects.where(:id => {'$nin' => options[:not_parent_ids]}, :parent_id => {'$nin' => options[:not_parent_ids]})
      #end
      #
      #if order_by[:target] != 'created_at'
      #  core_objects = core_objects.order_by([[order_by[:target], order_by[:order]], [:created_at, :desc]])
      #else
      #  core_objects = core_objects.order_by([[order_by[:target], order_by[:order]]])
      #end
      #
      ## get the link data in one query
      #root_ids = []
      #core_objects.each do |core_object|
      #  if core_object.parent_id
      #    root_ids << core_object.parent_id
      #  elsif !core_object._type == 'Talk'
      #    root_ids << core_object.id
      #  end
      #end
      #roots = CoreObject.where(:_id => {'$in' => root_ids}).to_a
      #
      ## build the structure
      #return_objects = []
      #core_objects.each do |core_object|
      #  root = roots.detect{|l| l.id == core_object.id || l.id == core_object.parent_id}
      #  return_objects << {:root => root, :original => core_object}
      #end
      #
      #return_objects
    end
  end

  protected

  # Set some denormilized user data
  def set_user_snippet
    self.build_user_snippet({public_id: user.public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
    self.user_snippet.id = user.id
  end

  def current_user_own
    grant_owner(user.id)
  end

  def update_denorms
    #TODO: implement when we allow editing of core objects
  end

end
require "limelight"

class Post
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
  field :response_count, :default => 0 # for talks, number of comments. for link/vid/pics, number of unique users talking / commenting
  field :talking_ids, :default => [] # ids of users talking about / commenting on this (not used for talks)
  field :tweet_id
  field :root_type
  field :embed_html # video embeds
  field :root_id, :type => BSON::ObjectId

  auto_increment :public_id

  embeds_one :user_snippet, :as => :user_assignable, :class_name => 'UserSnippet'
  embeds_one :response_to, :as => :core_object_assignable, :class_name => 'PostSnippet'
  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'
  embeds_many :likes, :as => :user_assignable, :class_name => 'UserSnippet'

  belongs_to :user

  validates :user_id, :status, :presence => true
  validate :title_length, :content_length, :unique_source

  attr_accessible :title, :content, :parent, :parent_id, :source_name, :source_url, :source_video_id, :embed_html, :tweet_content, :tweet, :tweet_id
  attr_accessor :parent, :parent_id, :source_name, :source_url, :source_video_id, :tweet_content, :tweet

  default_scope where('status' => 'active')

  before_validation :set_source_snippet
  before_create :set_user_snippet, :current_user_own, :send_tweet, :set_response_to, :set_root
  after_create :neo4j_create, :update_response_counts, :feed_post_create, :action_log_create, :add_initial_pop, :add_first_talk
  #after_update :expire_caches BETA REMOVE
  after_destroy :remove_from_feeds

  # MBM: hot damn lots of indexes. can we do this better? YES WE CAN
  # MCM: chill out obama
  # MBM: lolz
  # MBM: YES WE DID
  index [[ :public_id, Mongo::DESCENDING ]]
  index [[ :root_id, Mongo::DESCENDING ]]
  index "topic_mentions"
  index "user_mentions"
  index "likes"
  index "sources"
  index(
      [
        [ :user_id, Mongo::DESCENDING ],
        [ "likes", Mongo::DESCENDING ]
      ]
    ) # used in FeedUserItem

  def to_param
    "#{encoded_id}-#{name.parameterize[0..40].chomp('-')}"
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  # After a root post create, if there is content then create a linked talk for the user
  def add_first_talk
    unless self.class.name == 'Talk' || content.blank?
      user.talks.create(
              :content => content,
              :parent => self,
              :first_talk => true,
              :mention1 => mention1,
              :mention2 => mention2,
              :mention1_id => mention1_id,
              :mention2_id => mention2_id,
      )
    end
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

  def add_initial_pop
    add_pop_action(:new, :a, user)
  end

  def add_source(source)
    found = sources.detect{|existing| existing.name && existing.name.to_url == source.name.to_url}
    unless found
      self.sources << source
    end
  end

  # BETA REMOVE
  #def expire_caches
  #  ['list', 'grid', 'column'].each do |view|
  #    ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}")
  #    ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-top-response") # talk list view includes response on feeds but not on show pages.
  #    ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-bottom-response") # talk list view includes response on feeds but not on show pages.
  #    ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-top")
  #    ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-bottom")
  #  end
  #end

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
    if sources.length > 0 && !sources.first.url.blank? && !self.persisted?
      if Post.where('sources.url' => sources.first.url).first
        errors.add('Link', "has already been added to Limelight")
      end
    elsif sources.length > 0 && sources.first.url.blank?
      sources = nil
    end
  end

  def send_tweet
    if @tweet == '1' && @tweet_content && !@tweet_content.blank? && user.twitter
      user.twitter.update(@tweet_content)
    end
  end

  # Favorites BETA REMOVE
  #def favorited_by?(user_id)
  #  favorites.include? user_id
  #end
  #
  #def add_to_favorites(user)
  #  if favorited_by? user.id
  #    false
  #  else
  #    self.favorites << user.id
  #    self.favorites_count += 1
  #    user.add_to_favorites(self)
  #    Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, 2)
  #    true
  #  end
  #end
  #
  #def remove_from_favorites(user)
  #  if favorited_by? user.id
  #    self.favorites.delete(user.id)
  #    self.favorites_count -= 1
  #    user.remove_from_favorites(self)
  #    Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, -2)
  #    true
  #  else
  #    false
  #  end
  #end

  # Likes
  def liked_by?(user_id)
    likes.where(:_id => user_id).first
  end

  def add_to_likes(user)
    like = liked_by? user.id
    if like
      false
    elsif user_id == user.id
      nil
    else
      like = self.likes.new(user.attributes)
      like.id = user.id
      user.likes_count += 1
      add_pop_action(:lk, :a, user)
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, 1)
      Resque.enqueue(PushLike, id.to_s, user.id.to_s)

      true
    end
  end

  def push_like(user)
    ActionLike.create(:action => 'create', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedUserItem.like(user, self)
    FeedLikeItem.create(user, self)
  end

  def remove_from_likes(user)
    like = liked_by? user.id
    if like
      like.destroy
      user.likes_count -= 1
      add_pop_action(:lk, :r, user)
      Resque.enqueue(Neo4jPostAction, user.id.to_s, id.to_s, -1)
      Resque.enqueue(PushUnlike, id.to_s, user.id.to_s)

      true
    else
      false
    end
  end

  def push_unlike(user)
    ActionLike.create(:action => 'destroy', :from_id => user.id, :to_id => id, :to_type => self.class.name)
    FeedUserItem.unlike(user, self)
    FeedLikeItem.create(user, self)
  end

  ##
  # RESPONSES
  ##

  def set_response_to
    if parent || !parent_id.blank?
      unless parent
        self.parent = Post.find(parent_id)
      end
      if parent
        self.response_to = PostSnippet.new(:name => parent.title, :type => parent._type, :public_id => parent.public_id)
        self.response_to.id = parent.id
      end
    end
  end

  #TODO: background these response count functions

  def update_response_counts(u_id=nil)
    u_id ||= user_snippet.id
    if response_to
      parent ||= Post.find(response_to.id)
      parent.register_response(u_id)
    end
    register_topic_responses(u_id) if standalone_talk?
  end

  def register_response(u_id)
    unless talking_ids.include?(u_id)
      self.talking_ids << u_id
      self.response_count += 1
      self.save
      register_topic_responses(u_id)
    end
  end

  def register_topic_responses(u_id)
    mentioned_topics.each do |topic|
      unless topic.talking_ids.include?(u_id)
        topic.talking_ids << u_id
        topic.response_count += 1
        topic.save
      end
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

  def feed_post_create
    Resque.enqueue(PushPostToFeeds, id.to_s)
  end

  def push_to_feeds
    FeedUserItem.post_create(self)
    FeedTopicItem.post_create(self) unless response_to || topic_mentions.empty?
    FeedContributeItem.create(self)
  end

  def set_root
    if response_to
      self.root_id = response_to.id
      self.root_type = response_to.type
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

  def standalone_talk?
    _type == "Talk" && !response_to
  end

  def disable
    self.status = 'disabled'
    Resque.enqueue(PushPostDisable, id.to_s)
  end

  def push_disable
    FeedUserItem.post_disable(self, (self.class.name == 'Talk' && !is_popular))
    FeedTopicItem.post_disable(self) unless self.class.name == 'Talk' && !is_popular
    FeedContributeItem.disable(self)
  end

  class << self
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end

    # Build and return a post based on params (does not save)
    def post(params, user_id)

      # set the image
      params[:asset_image] = {
              :remote_image_url => params[:remote_image_url],
              :image_cache => params[:image_cache]
      }

      if params[:type] && ['Video', 'Picture', 'Link', 'Talk'].include?(params[:type])
        post = Kernel.const_get(params[:type]).new(params)
        post.user_id = user_id

        # Is the post an original root?
        unless post.class.name == 'Talk'
          post.save_original_image
          post.save_images
        end
      else
        post = Post.new
      end
      post
    end

    def friend_responses(id, user)
      Post.where(:root_id => id, "user_snippet._id" => {"$in" => user.following_users})
    end

    def for_show_page(parent_id)
      Post.where(:root_id => parent_id).order_by(:created_at, :desc)
    end

    # @example Fetch the core_objects for a feed with the given criteria
    #   Post.feed
    #
    # @param [ display_types ] Array of Post types to fetch for the feed
    # @param { order_by } Array of format { 'target' => 'field', 'order' => 'direction' } to sort the feed
    # @param { options } Options TODO: Fill out these options
    #
    # @return [ Posts ]
    def feed(feed_id, display_types, order_by, page)

      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedUserItem.where(:feed_id => feed_id, :root_type => {'$in' => display_types})
      if order_by == 'newest'
        items = items.order_by(:last_response_time, :desc)
      else
        items = items.order_by(:rel, :desc)
      end
      items = items.skip((page-1)*20).limit(20)

      build_feed(items)
    end

    def contribute_feed(feed_id, display_types, order_by, page)
      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedContributeItem.where(:feed_id => feed_id, :root_type => {'$in' => display_types})
      if order_by == 'newest'
        items = items.order_by(:last_response_time, :desc)
      else
        items = items.order_by(:p, :desc)
      end
      items = items.skip((page-1)*20).limit(20)

      build_feed(items)
    end

    def like_feed(feed_id, display_types, order_by, page)
      if display_types.include?('Talk')
        display_types << 'Topic'
      end

      items = FeedLikeItem.where(:feed_id => feed_id, :root_type => {'$in' => display_types})
      if order_by == 'newest'
        items = items.order_by(:last_response_time, :desc)
      else
        items = items.order_by(:p, :desc)
      end
      items = items.skip((page-1)*20).limit(20)

      build_feed(items)
    end

    def topic_feed(feed_ids, user_id, display_types, order_by, page)
      items = FeedTopicItem.where(:root_type => {'$in' => display_types}, :mentions.in => feed_ids)
      if order_by == 'newest'
        items = items.order_by(:last_response_time, :desc)
      else
        items = items.order_by(:p, :desc)
      end
      items = items.skip((page-1)*20).limit(20)

      user_items = FeedUserItem.where(:feed_id => user_id, :root_id => {'$in' => items.map{|i| i.root_id}}).to_a
      build_topic_feed(items, user_items, feed_ids)
    end

    def build_topic_feed(items, user_items, feed_ids)
      item_ids = []
      items.each do |i|
        item_ids << i.root_id
        user_i = user_items.detect{ |ui| ui.root_id == i.root_id }
        item_ids += user_i.responses.last(2) if user_i && user_i.responses

        overlap = (i.root_mentions & feed_ids) ? (i.root_mentions & feed_ids).first : false

        # if we are not on a topic feed mentioned in root mentions, show the latest object that mentions this topic feed
        if !overlap && i.responses
          overlap = (i.responses.keys & feed_ids.map{|f| f.to_s}).first
          item_ids << i.responses[overlap] if overlap
        end
      end

      objects = Post.where(:_id => {'$in' => item_ids})

      return_objects = []
      items.each do |i|
        root = objects.detect{|o| o.id == i.root_id}
        user_i = user_items.detect{ |ui| ui.root_id == i.root_id }
        user_responses = objects.select{ |o| user_i && user_i.responses && user_i.responses.include?(o.id) }

        overlap = (i.root_mentions & feed_ids) ? (i.root_mentions & feed_ids).first : false
        if !overlap && i.responses
          overlap = (i.responses.keys & feed_ids.map{|f| f.to_s}).first
          topic_responses = objects.select{ |o| i.responses[overlap] == o.id }
        else
          topic_responses = []
        end

        return_objects << { :root => root, :responses => user_responses, :topic_responses => topic_responses }
      end

      return_objects
    end

    def build_feed(items)
      topic_ids = []
      item_ids = []
      items.each do |i|
        if i.root_type == 'Topic'
          topic_ids << i.root_id
        else
          item_ids << i.root_id
        end
        item_ids += i.responses.last(2) if i.responses
      end

      topics = topic_ids.length > 0 ? Topic.where(:_id => {'$in' => topic_ids}) : []
      objects = Post.where(:_id => {'$in' => item_ids})

      return_objects = []
      items.each do |i|
        root_post = RootPost.new
        if i.root_type == 'Topic'
          root_post.root = topics.detect{|t| t.id == i.root_id}
        else
          root_post.root = objects.detect{|o| o.id == i.root_id}
        end

        root_post.responses = objects.select{|o| i.responses && i.responses.include?(o.id)}
        root_post.personal_talking = i.responses ? i.responses.length : 0
        root_post.public_talking = root_post.root.response_count

        return_objects << root_post
      end

      return_objects
    end
  end

  protected

  # Set some denormilized user data
  def set_user_snippet
    self.build_user_snippet({:public_id => user.public_id, :username => user.username, :first_name => user.first_name, :last_name => user.last_name})
    self.user_snippet.id = user.id
  end

  def current_user_own
    grant_owner(user.id)
  end

  def update_denorms
    #TODO: implement when we allow editing of core objects
  end

end
require "limelight"

class CoreObject
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Voting
  include Limelight::Mentions
  include Limelight::Popularity

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name TODO: update this once notifications are implemented
  #TODO: bug: each core object type currently validates the length of content, but after creation content_raw is copied to content.
  #TODO: since the topic and user mentions in raw content increase the length, validation may fail when the obj is saved again
  field :title

  field :content

  field :status, :default => 'active'
  field :favorites, :default => []
  field :favorites_count, :default => 0
  field :reposts, :default => []
  field :reposts_count, :default => 0
  field :user_id
  field :response_count, :default => 0

  auto_increment :public_id

  embeds_one :user_snippet, as: :user_assignable
  embeds_one :response_to
  embeds_many :sources, :as => :has_source, :class_name => 'SourceSnippet'

  belongs_to :user

  validates :user_id, :status, :presence => true
  validate :title_length, :content_length

  attr_accessible :title, :content, :response_to_id, :source_name, :source_url, :source_video_id, :tweet_content, :tweet
  attr_accessor :response_to_id, :source_name, :source_url, :source_video_id, :tweet_content, :tweet

  before_validation :set_source_snippet
  before_create :set_user_snippet, :current_user_own, :set_response_snippet, :send_tweet
  after_create :update_response_count
  after_update :expire_caches

  # hot damn lots of indexes. can we do this better?
  index :user_id
  index :reposts
  index :favorites
  index :public_id, unique: true
  index :created_at
  index :ph
  index :pd
  index :pw
  index :pm
  index :pt
  index "topic_mentions._id"
  index "user_mentions._id"
  index "response_to._id"

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
      ActionController::Base.new.expire_fragment("teaser-#{id.to_s}-#{view}-response") # talk list view includes response on feeds but not on show pages.
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
      errors.add(:title, "must be less than 125 characters long")
    end
  end

  def content_length
    if content_clean.length > 200
      errors.add(:content, "must be less than 200 characters long")
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
    unless favorited_by? user.id
      self.favorites << user.id
      self.favorites_count += 1
      user.add_to_favorites(self)
      true
    else
      false
    end
  end

  def remove_from_favorites(user)
    if favorited_by? user.id
      self.favorites.delete(user.id)
      self.favorites_count -= 1
      user.remove_from_favorites(self)
      true
    else
      false
    end
  end

  # Reposts
  def reposted_by?(user_id)
    reposts.include? user_id
  end

  def add_to_reposts(user)
    if (reposted_by? user.id) || (user_id == user.id)
      false
    else
      self.reposts << user.id
      self.reposts_count += 1
      user.reposts_count += 1
      true
    end
  end

  def remove_from_reposts(user)
    if reposted_by? user.id
      self.reposts.delete(user.id)
      self.reposts_count -= 1
      user.reposts_count -= 1
      true
    else
      false
    end
  end

  def set_response_snippet
    unless !@response_to_id || @response_to_id.blank?
      target = CoreObject.find(@response_to_id)
      if target
        self.response_to = ResponseTo.new(
                :type => target._type,
                :title => target.title_clean,
                :public_id => target.public_id
        )
        self.response_to.id = target.id
      end
    end
  end

  def update_response_count
    if (response_to)
      CoreObject.collection.update(
        {:_id => response_to.id},
        {
          "$inc" => { :response_count => 1 }
        }
      )
    end
  end

  class << self
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end

    # @example Fetch the core_objects for a feed with the given criteria
    #   CoreObject.feed
    #
    # @param [ display_types ] Array of CoreObject types to fetch for the feed
    # @param { order_by } Array of format { 'target' => 'field', 'order' => 'direction' } to sort the feed
    # @param { options } Options TODO: Fill out these options
    #
    # @return [ CoreObjects ]
    def feed(display_types, order_by, options)
      or_criteria = []
      or_criteria << {:_id.in => options[:includes_ids]} if options[:includes_ids]
      or_criteria << {:user_id.in => options[:created_by_users]} if options[:created_by_users]
      or_criteria << {:reposts.in => options[:reposted_by_users]} if options[:reposted_by_users]
      or_criteria << {"topic_mentions._id" => {"$in" => options[:mentions_topics]}} if options[:mentions_topics]
      or_criteria << {"user_mentions._id" => {"$in" => options[:mentions_users]}} if options[:mentions_users]
      or_criteria << {"response_to._id" => options[:response_to_id]} if options[:response_to_id]

      #page length also hard-coded in views/core_object
      page_length = options[:limit]? options[:limit] - 1 : 30
      page_number = options[:page]? options[:page] : 1
      num_to_skip = page_length * (page_number - 1)

      # page_length + 1 is used below so that one extra object is returned, allowing the views to check if there are more objects
      if (or_criteria.length > 0)
        core_objects = self.any_in("_type" => display_types).where(:status => "active").any_of(or_criteria).skip(num_to_skip).limit(page_length + 1)
      else
        core_objects = self.any_in("_type" => display_types).where(:status => "active").skip(num_to_skip).limit(page_length + 1)
      end

      if order_by[:target] != 'created_at'
        core_objects.order_by([order_by[:target], order_by[:order], [:created_at, :desc]])
      else
        core_objects.order_by([order_by[:target], order_by[:order]])
      end
    end
  end

  protected

  # Set some denormilized user data
  def set_user_snippet
    self.build_user_snippet({id: user.id, public_id: user.public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  def current_user_own
    grant_owner(user.id)
  end

  def update_denorms
    #TODO: implement when we allow editing of core objects
  end

end
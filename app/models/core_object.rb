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
  # Notification.shared_object_snippet.name (for talk only, other objects use Title) TODO: update this when notifications get implemented
  field :content
  #TODO: bug: each core object type currently validates the length of content, but after creation content_raw is copied to content.
  #TODO: since the topic and user mentions in raw content increase the length, validation may fail when the obj is saved again

  field :status, :default => 'Active'
  field :favorites, :default => []
  field :favorites_count, :default => 0
  field :reposts, :default => []
  field :reposts_count, :default => 0
  field :user_id
  field :response_count, :default => 0

  auto_increment :public_id

  embeds_one :user_snippet, as: :user_assignable
  embeds_one :response_to

  index :public_id, unique: true

  belongs_to :user
  has_many :core_object_shares
  validates :user_id, :status, :presence => true
  attr_accessible :content, :response_to_id
  attr_accessor :response_to_id

  before_create :set_user_snippet, :current_user_own, :set_response_snippet
  after_create :update_response_count

  def to_param
    "#{encoded_id}-#{name.parameterize[0..40]}"
  end

  def content_clean
    content.gsub(/[\#\@]\[([0-9a-zA-Z]*)#([\w ]*)\]/, '\2')
  end

  def encoded_id
    public_id.to_i.to_s(36)
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
                :title => target.title,
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
      or_criteria << {:user_id.in => options[:created_by_users]} if options[:created_by_users]
      or_criteria << {:reposts.in => options[:reposted_by_users]} if options[:reposted_by_users]
      or_criteria << {"topic_mentions._id" => {"$in" => options[:mentions_topics]}} if options[:mentions_topics]
      or_criteria << {"user_mentions._id" => {"$in" => options[:mentions_users]}} if options[:mentions_users]
      or_criteria << {"response_to._id" => options[:response_to_id]} if options[:response_to_id]
      or_criteria << {:_id.in => options[:includes_ids]} if options[:includes_ids]

      #page length also hard-coded in views/core_object
      page_length = options[:limit]? options[:limit] - 1 : 15
      page_number = options[:page]? options[:page] : 1
      num_to_skip = page_length * (page_number - 1)

      # page_length + 1 is used below so that one extra object is returned, allowing the views to check if there are more objects
      if (or_criteria.length > 0)
        core_objects = self.any_in("_type" => display_types).any_of(or_criteria).skip(num_to_skip).limit(page_length + 1)
      else
        core_objects = self.any_in("_type" => display_types).skip(num_to_skip).limit(page_length + 1)
      end

      core_objects.order_by([order_by[:target], order_by[:order]])
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

end
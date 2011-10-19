require "limelight"

class CoreObject
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Voting

  # Denormilized:
  # Notification.shared_object_snippet.name (for talk only, other objects use Title) TODO: update this when notifications get implemented
  field :content

  field :status, :default => 'Active'
  field :favorites, :default => []
  field :favorites_count, :default => 0
  field :reposts, :default => []
  field :reposts_count, :default => 0
  field :user_id

  auto_increment :_public_id

  embeds_one :user_snippet, as: :user_assignable
  embeds_one :response_to
  embeds_many :user_mentions, as: :user_mentionable
  embeds_many :topic_mentions, as: :topic_mentionable

  index :_public_id, unique: true

  belongs_to :user
  has_many :core_object_shares
  validates :user_id, :status, :presence => true
  attr_accessible :content, :content_raw
  attr_accessor :content_raw

  before_create :set_user_snippet, :set_mentions, :current_user_own

  def to_param
    "#{self._public_id.to_i.to_s(36)}-#{name.parameterize}"
  end

  def content_clean
    content.gsub(/[\#\@]\[([0-9a-zA-Z]*)#([\w ]*)\]/, '\2')
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
    end
  end

  def remove_from_favorites(user)
    if favorited_by? user.id
      self.favorites.delete(user.id)
      self.favorites_count -= 1
      user.remove_from_favorites(self)
    end
  end

  # Reposts
  def reposted_by?(user_id)
    reposts.include? user_id
  end

  def add_to_reposts(user)
    unless reposted_by? user.id
      self.reposts << user.id
      self.reposts_count += 1
      user.reposts_count += 1
    end
  end

  def remove_from_reposts(user)
    if reposted_by? user.id
      self.reposts.delete(user.id)
      self.reposts_count -= 1
      user.reposts_count -= 1
    end
  end

  def public_id
    self[_public_id].to_i.to_s(36)
  end

  class << self
    def find_by_encoded_id(id)
      where(:_public_id => id.to_i(36)).first
    end

    # @example Fetch the core_objects for a feed with the given criteria
    #   CoreObject.feed
    #
    # @param [ display_types ] Array of CoreObject types to fetch for the feed
    # @param [ order_by ] Array of format [field, direction] to sort the feed
    # @param { options } Options TODO: Fill out these options
    #
    # @return [ CoreObjects ]
    def feed(display_types, order_by, options)
      or_criteria = []
      or_criteria << {:user_id.in => options[:created_by_users]} if options[:created_by_users]
      or_criteria << {:reposts.in => options[:reposted_by_users]} if options[:reposted_by_users]
      or_criteria << {"topic_mentions._id" => {"$in" => options[:mentions_topics]}} if options[:mentions_topics]
      or_criteria << {"user_mentions._id" => {"$in" => options[:mentions_users]}} if options[:mentions_users]
      or_criteria << {:_id.in => options[:includes_ids]} if options[:includes_ids]

      page_length = 3
      page_number = options[:page]? options[:page] : 1
      num_to_skip = page_length * (page_number - 1)

      # page_length + 1 is used below so that one extra object is returned, allowing the views to check if there are more objects
      if (or_criteria.length > 0)
        core_objects = self.any_in("_type" => display_types).any_of(or_criteria).skip(num_to_skip).limit(page_length + 1)
      else
        core_objects = self.any_in("_type" => display_types).skip(num_to_skip).limit(page_length + 1)
      end

      core_objects.order_by([order_by])
    end
  end

  protected

  # Set some denormilized user data
  def set_user_snippet
    self.build_user_snippet({id: user.id, _public_id: user._public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  def set_mentions
    set_user_mentions
    set_topic_mentions
    self.content = @content_raw
  end

  # Checks @content_raw for user mentions
  def set_user_mentions
    return unless @content_raw
    found_users = Array.new
    # Searches for strings contained between @[uid#username] delimiters. Returns an array of arrays of format [[uid,username],[uid,username]...].
    @content_raw.scan(/\@\[([0-9a-zA-Z]*)#([\w]*)\]/).map do |user|
      unless found_users.include? user[0]
        found_users << user[0]
      end
    end

    # Find the users
    users = User.where(:_id.in => found_users)

    users.each do |user|
      self.user_mentions.build({id: user.id, _public_id: user._public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
    end
  end

  # Checks @content_raw for topic mentions
  def set_topic_mentions
    return unless @content_raw
    if @content_raw
      found_topics = Array.new
      # Searches for strings contained between #[uid#topic_name] delimiters. Returns an array of arrays of format [[uid,topic_name],[uid,topic_name]...].
      @content_raw.scan(/\#\[([0-9a-zA-Z]*)#([\w ]*)\]/).map do |topic|
        unless found_topics.include? topic[0]
          found_topics << topic[0]
        end
      end

      # Add the found topics as snippets
      mentions = Topic.where(:_id.in => found_topics)
      mentions.each do |topic|
        payload = {id: topic.id, _public_id: topic._public_id, name: topic.name, slug: topic.slug }
        self.topic_mentions.build(payload)
      end

      # Explodes the string. Returns an array of arrays containting
      # [string, slugified string] without duplicates.
      new_topic_mentions = @content_raw.scan(/\#\[([\w ]*[^#])\]/).flatten(1).map do |topic|
        [topic.strip, topic.to_url]
      end.uniq

      # See if any of the topic slugs are already in the DB. Check through topic aliases!
      topic_slugs = topic_mentions.map { |data| data[1] }
      topics = Topic.where("aliases" => { '$in' => topic_slugs})

      new_topic_mentions.each do |topic_mention|
        found_topic = false
        # Do we already have a DB topic for this mention?
        topics.each do |topic|
          if topic.slug == topic_mention[1]
            found_topic = topic
          end
        end
        # If we did not find the topic, create it and save it if it is valid
        if found_topic == false
          found_topic = user.topics.build({name: topic_mention[0]})
          if found_topic.valid?
            found_topic.save
            # add the new ID to the topic mention
            @content_raw.gsub!(/\#\[#{topic_mention[0]}\]/, "#[#{found_topic.id.to_s}##{topic_mention[0]}]")
          else
            found_topic = false
          end
        end
        if found_topic
          payload = {id: found_topic.id, _public_id: found_topic._public_id, name: found_topic.name, slug: found_topic.slug }
          self.topic_mentions.build(payload)
        end
      end
    end
  end

  def current_user_own
    grant_owner(user.id)
  end

end
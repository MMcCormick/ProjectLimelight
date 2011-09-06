require "acl"

class CoreObject
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl

  field :content
  field :status, :default => 'Active'
  field :favorited_by, :default => []
  field :user_id

  embeds_one :user_snippet, as: :user_assignable
  embeds_one :response_to
  embeds_many :user_mentions, as: :user_mentionable
  embeds_many :topic_mentions, as: :topic_mentionable

  belongs_to :user
  validates :user_id, :status, :presence => true
  attr_accessible :content

  def set_user_snippet(user)
    self.build_user_snippet({id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  def is_following_user?(user_id)
    self.following_users.include? user_id
  end

  def toggle_follow_user(user)
    if is_following_user? user.id
      unfollow_user user
    else
      follow_user user
    end
  end

  def follow_user(user)
    if !self.following_users.include?(user.id)
      self.following_users << user.id
      self.following_users_count += 1
      user.followers_count += 1
    end
  end

  def unfollow_user(user)
    if self.following_users.include?(user.id)
      self.following_users.delete(user.id)
      self.following_users_count -= 1
      user.followers_count -= 1
    end
  end

  def set_mentions
    set_user_mentions
    set_topic_mentions
  end

  # Searches the content attribute for [@foo] mentions.
  # For each found, check if user is in DB and add as UserMention to this object if found.
  def set_user_mentions
    # Searches for strings contained between [@] delimiters. Returns an array of slugified strings without duplicates.
    user_mention_slugs = self.content.scan(/(?<=\[@)(.*?)(?=\])/).flatten(1).map! do |user|
      user.to_url
    end.uniq

    # See if any of the user slugs are already in the DB. Check through topic aliases!
    users = User.any_in("slug" => user_mention_slugs)

    users.each do |user|
      self.user_mentions.build({id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name})
    end
  end

  # Searches the content attribute for [#foo] mentions.
  # For each found, check if topic is in DB. If valid and not in DB, create it.
  # For each valid topic mention, add as TopicMention to this object.
  def set_topic_mentions
    # Searches for strings contained between [#] delimiters. Returns an array of slugified strings without duplicates.
    topic_mentions = self.content.scan(/(?<=\[#)(.*?)(?=\])/).flatten(1).map! do |topic|
      [topic, topic.to_url]
    end.uniq

    # See if any of the topic slugs are already in the DB. Check through topic aliases!
    topic_slugs = topic_mentions.map { |data| data[1] }
    topics = Topic.any_in("aliases" => topic_slugs)

    topic_mentions.each do |topic_mention|
      found_topic = false
      # Do we already have a DB topic for this mention?
      topics.each do |topic|
        if topic.slug == topic_mention[1]
          found_topic = topic
        end
      end
      # If we did not find the topic, create it and save it if it is valid
      if found_topic == false
        found_topic = self.user.topics.build({name: topic_mention[0]})
        if found_topic.valid?
          found_topic.save
        else
          found_topic = false
        end
      end
      if found_topic
        payload = {id: found_topic.id, name: found_topic.name}
        self.topic_mentions.build(payload)
      end
    end
  end


  # @example Fetch the core_objects for a feed with the given criteria
  #   CoreObject.feed
  #
  # @param [ display_types ] Array of CoreObject types to fetch for the feed
  # @param [ order_by ] Array of format [field, direction] to sort the feed
  # @param { options } Options TODO: Fill out these options
  #
  # @return [ CoreObjects ]
  def self.feed(display_types, order_by, options)
    or_criteria = []
    or_criteria << {:user_id.in => options[:created_by_users]} if options[:created_by_users]
    or_criteria << {"topic_mentions._id.in" => options[:mentions_topics]} if options[:mentions_topics]
    or_criteria << {"user_mentions._id.in" => options[:mentions_users]} if options[:mentions_users]

    if (or_criteria.length > 0)
      core_objects = self.any_in("_type" => display_types).any_of(or_criteria)
    else
      core_objects = self.any_in("_type" => display_types)
    end

    core_objects.order_by([order_by])
  end
end
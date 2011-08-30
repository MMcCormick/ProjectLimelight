class CoreObject
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :content
  field :status, :default => 'Active'
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
end
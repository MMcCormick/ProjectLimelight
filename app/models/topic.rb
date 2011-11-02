require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Images
  include Limelight::Popularity

  # Denormilized:
  # CoreObject.topic_mentions.name
  # TopicConnectionSnippet.topic_name
  field :name

  # Denormilized:
  # Topic.aliases
  # TopicMention.slug
  # TopicConnectionSnippet.topic_slug
  slug :name, :v do |doc|
    if doc.topic_type_snippets.empty?
      doc.name
    else
      doc.name + " " + doc.topic_type_snippets[0].name.to_url
    end
  end

  field :summary
  field :status, :default => 'Active'
  field :aliases
  field :user_id
  field :followers_count, :default => 0
  field :v, :default => 1

  auto_increment :public_id

  belongs_to :user
  embeds_many :topic_type_snippets
  embeds_many :topic_connection_snippets

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 30 }
  attr_accessible :name, :summary

  before_create :add_alias
  after_create :add_to_soulmate
  before_update :update_alias
  after_update :update_denorms
  before_destroy :remove_from_soulmate

  # Return the topic slug instead of its ID
  def to_param
    self.slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  def add_alias
    self.aliases ||= []
    url = name.to_url
    self.aliases << url unless self.aliases.include?(url)
    # TODO: decide about pluralization of topic aliases
    #plurl = name.pluralize == name ? name.singularize.to_url : name.pluralize.to_url
    #self.aliases << plurl unless self.aliases.include?(plurl)
  end

  def update_alias
    if name_changed?
      aliases.delete(name_was.to_url)
      aliases << name.to_url
    end
  end

  def has_alias? name
    aliases.include? name
  end

  def types_array
    topic_type_snippets.map {|type| type.name}
  end

  def add_to_soulmate
    Resque.enqueue(SmCreateTopic, id.to_s)
  end

  def remove_from_soulmate
    Resque.enqueue(SmDestroyTopic, id.to_s)
  end

  def add_connection(connection, con_topic, user)
    self.add_connection_helper(connection, con_topic, user)
    if !connection.opposite.blank? && opposite = TopicConnection.find(connection.opposite)
      con_topic.add_connection_helper(opposite, self, user)
    end
  end

  def add_connection_helper(connection, con_topic, user)
    snippet = TopicConnectionSnippet.new()
    snippet.id = connection.id
    snippet.name = connection.name
    snippet.pull_from = connection.pull_from
    snippet.topic_id = con_topic.id
    snippet.user_id = user.id
    self.topic_connection_snippets << snippet
  end

  # Gets connections, returning a hash of the following format
  # connections => {:connection_id => {:name => "Products", :topics => [topic1, topic2]}}
  def get_connections
    topic_ids = topic_connection_snippets.map { |snippet| snippet.topic_id }
    topics = Topic.where(:_id.in => topic_ids).desc(:pt)
    connections = {}

    topics.each do |topic|
      snippet = topic_connection_snippets.detect {|snippet| topic.id == snippet.topic_id }
      connections[snippet.id] ||= {:name => snippet.name, :topics => []}
      connections[snippet.id][:topics] << topic
    end

    connections
  end

  def pull_from_ids
    pull_from_ids = []
    topic_connection_snippets.each do |snippet|
      if snippet.pull_from?
        pull_from_ids << snippet.topic_id
      end
    end

    pull_from_ids
  end

  class << self
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end
  end

  protected

  #TODO: topic aliases
  #TODO: update soulmate
  def update_denorms
    topic_mention_updates = {}
    if name_changed?
      topic_mention_updates["topic_mentions.$.name"] = self.name
    end
    if slug_changed?
      topic_mention_updates["topic_mentions.$.slug"] = self.slug
    end

    if !topic_mention_updates.empty?
      CoreObject.where("topic_mentions._id" => id).update_all(topic_mention_updates)
      Resque.enqueue(SmCreateTopic, id.to_s)
    end

  end
end

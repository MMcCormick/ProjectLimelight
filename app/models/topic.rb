require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl
  include Limelight::Images

  # Denormilized:
  # CoreObject.topic_mentions.name
  field :name

  # Denormilized:
  # Topic.aliases
  # TopicMention.slug
  slug :name

  field :summary
  field :status, :default => 'Active'
  field :aliases
  field :user_id
  field :followers_count, :default => 0

  auto_increment :public_id

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable
  embeds_many :topic_type_snippets

  validates :user_id, :presence => true
  validates :name, :presence => true, :length => { :minimum => 2, :maximum => 30 }
  attr_accessible :name, :summary

  before_create :add_alias, :set_user_snippet
  after_create :add_to_soulmate
  after_update :update_denorms
  before_destroy :remove_from_soulmate

  # Return the topic slug instead of its ID
  def to_param
    self.slug
  end

  def encoded_id
    public_id.to_i.to_s(36)
  end

  def set_user_snippet
    self.build_user_snippet({id: user.id, public_id: user.public_id, username: user.username, first_name: user.first_name, last_name: user.last_name})
  end

  def add_alias
    self.aliases ||= []
    url = name.to_url
    self.aliases << url unless self.aliases.include?(url)
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

  class << self
    def find_by_encoded_id(id)
      where(:public_id => id.to_i(36)).first
    end
  end

  protected

  #TODO: topic aliases
  def update_denorms
    topic_mention_updates = {}
    if name_changed?
      topic_mention_updates["topic_mentions.$.name"] = self.name
    end
    if slug_changed?
      topic_mention_updates["topic_mentions.$.slug"] = self.slug
      aliases.delete(slug_was)
      aliases << slug
    end
    if !topic_mention_updates.empty?
      CoreObject.where("topic_mentions._id" => id).update_all(topic_mention_updates)
    end
  end
end

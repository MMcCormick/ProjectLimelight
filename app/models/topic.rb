require "limelight"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl

  # Denormilized:
  # CoreObject.topic_mentions.name
  field :name

  # Denormilized:
  # Topic.aliases
  # TopicMention.slug
  slug :name

  field :status, :default => 'Active'
  field :aliases
  field :user_id
  field :followers_count, :default => 0

  auto_increment :_public_id

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable
  embeds_many :topic_type_snippets

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :status, :presence => true
  attr_accessible :name

  before_create :add_alias

  # Return the topic slug instead of its ID
  def to_param
    self.slug
  end

  def add_alias
    self.aliases ||= []
    url = name.to_url
    self.aliases << url unless self.aliases.include?(url)
  end

  def public_id
    self[_public_id].to_i.to_s(36)
  end

  class << self
    def find_by_encoded_id(id)
      where(:_public_id => id.to_i(36)).first
    end
  end
end

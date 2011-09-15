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
  slug :name

  field :status, :default => 'Active'
  field :aliases
  field :user_id
  field :followers_count, :default => 0

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable

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
end

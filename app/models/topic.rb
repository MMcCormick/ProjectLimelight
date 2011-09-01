require "acl"

class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps
  include Limelight::Acl

  # Denormilized:
  # CoreObject.topic_mentions.name
  field :name

  field :status, :default => 'Active'
  field :aliases
  field :user_id

  # Denormilized:
  # Topic.aliases
  slug :name

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :status, :presence => true
  attr_accessible :name

  before_create :add_alias

  protected
  def add_alias
    self.aliases = Array.new unless !self.aliases.nil?
    self.aliases << name.to_url unless self.aliases.include?(name.to_url)
  end
end

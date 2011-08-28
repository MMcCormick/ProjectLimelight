class Topic
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :name, :type => String
  field :user_id, :type => Integer
  slug :name

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable

  validates :user_id, :presence => true
  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  attr_accessible :name
end

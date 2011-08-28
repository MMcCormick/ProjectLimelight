class CoreObject
  include Mongoid::Document
  include Mongoid::Slug
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :content, :type => String
  field :user_id, :type => Integer

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable
  validates :user_id, :presence => true
  attr_accessible :content
end
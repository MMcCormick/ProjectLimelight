class CoreObject
  include Mongoid::Document
  include Mongoid::Paranoia
  include Mongoid::Timestamps

  field :content, :type => String
  field :user_id, :type => Integer

  belongs_to :user
  embeds_one :user_snippet, as: :user_assignable
  validates :user_id, :presence => true
  attr_accessible :content, :user, :user_snippet
end

# Embeddable user snippet that holds useful (denormalized) user info on various db objects
class UserSnippet
  include Mongoid::Document

  field :username, :type => String
  field :first_name, :type => String
  field :last_name, :type => String

  embedded_in :user_assignable, polymorphic: true

  attr_accessible :username, :first_name, :last_name
end
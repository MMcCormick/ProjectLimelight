# Embeddable user snippet that holds useful (denormalized) user info
class UserSnippet
  include Mongoid::Document

  field :username
  field :first_name
  field :last_name
  field :public_id

  embedded_in :user_assignable, polymorphic: true

  attr_accessible :username, :first_name, :last_name, :public_id

  # Return the users username instead of their ID
  def to_param
    username.to_url
  end
end
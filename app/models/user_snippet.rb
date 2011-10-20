# Embeddable user snippet that holds useful (denormalized) user info
class UserSnippet
  include Mongoid::Document

  field :username
  field :first_name
  field :last_name
  field :public_id

  embedded_in :user_assignable, polymorphic: true

  # Return the users username instead of their ID
  def to_param
    self.username
  end
end
# Embeddable user snippet that holds useful (denormalized) user info
class UserSnippet
  include Mongoid::Document

  field :username, :type => String
  field :first_name, :type => String
  field :last_name, :type => String

  embedded_in :user_assignable, polymorphic: true
end
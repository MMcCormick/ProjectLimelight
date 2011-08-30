# Embeddable user snippet that holds useful (denormalized) user info
class UserMention
  include Mongoid::Document

  field :username
  field :first_name
  field :last_name

  embedded_in :user_mentionable, polymorphic: true

end
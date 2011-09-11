# Embeddable user snippet that holds useful (denormalized) user info - with timestamps
class NotificationReceiverSnippet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :username
  field :first_name
  field :last_name

  embedded_in :notification
end
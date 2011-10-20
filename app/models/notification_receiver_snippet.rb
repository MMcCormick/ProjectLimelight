# Embeddable user snippet that holds useful (denormalized) user info - with timestamps
class NotificationReceiverSnippet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :username
  field :first_name
  field :last_name
  field :public_id

  embedded_in :notification

  # Return the users username instead of their ID
  def to_param
    self.username
  end
end
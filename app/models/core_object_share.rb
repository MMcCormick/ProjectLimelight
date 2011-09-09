class CoreObjectShare < Notification

  belongs_to :user
  belongs_to :core_object

  validates_presence_of :user_id, :sender_snippet, :shared_object_snippet
  attr_accessible :core_object_id

end
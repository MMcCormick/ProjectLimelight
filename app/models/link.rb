class Link < CoreObject
  include Limelight::Images

  attr_accessible :title

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name TODO: update this once notifications are implemented
  field :title

  validate :has_valid_url
  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :maximum => 400 }

  def name
    self.title
  end
end
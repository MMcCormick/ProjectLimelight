class Video < CoreObject

  attr_accessible :title

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name
  field :title

  validates :title, :length => { :minimum => 5, :maximum => 75 }, :presence => true

  def name
    self.title
  end
end

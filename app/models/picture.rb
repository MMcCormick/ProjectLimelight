class Picture < CoreObject
  include Limelight::Images

  attr_accessible :url, :title

  field :url

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name
  field :title

  validates :title, :length => { :minimum => 5, :maximum => 50 }, :presence => true
  validates_format_of :url, :with => URI::regexp, :allow_nil => true

  def name
    self.title
  end

end
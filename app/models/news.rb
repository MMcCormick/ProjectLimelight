class News < CoreObject
  include Limelight::Images

  attr_accessible :title, :url

  field :url

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name
  field :title

  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :minimum => 5, :maximum => 400 }
  #validates_format_of :url, :with => URI::regexp(%w(http https))

  def name
    self.title
  end
end
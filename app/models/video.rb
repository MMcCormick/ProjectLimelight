class Video < CoreObject

  attr_accessible :url, :title, :provider_name, :provider_video_id

  field :url
  field :provider_name
  field :provider_video_id

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name
  field :title

  validates :title, :length => { :minimum => 5, :maximum => 75 }, :presence => true
  validates_format_of :url, :with => URI::regexp(%w(http https))
  validates :provider_name, :presence => true
  validates :provider_video_id, :presence => true

  def name
    self.title
  end
end

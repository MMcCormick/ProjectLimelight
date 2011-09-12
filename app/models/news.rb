class News < CoreObject
  attr_accessible :title, :image

  field :url

  # Denormilized:
  # CoreObject.response_to.name
  # CoreObjectShare.core_object_snippet.name
  field :title

  mount_uploader :image, ImageUploader

  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :minimum => 5, :maximum => 400 }
  #validates_format_of :url, :with => URI::regexp(%w(http https))

  def name
    self.title
  end
end

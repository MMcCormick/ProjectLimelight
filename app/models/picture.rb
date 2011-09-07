class Picture < CoreObject
  attr_accessible :url, :title, :image

  field :url, :type => String

  # Denormilized:
  # CoreObject.response_to.name
  field :title, :type => String

  slug :title

  mount_uploader :image, ImageUploader

  validates :title, :length => { :minimum => 5, :maximum => 50 },
                    :presence => true
  validates :url, :presence => true
  validates_format_of :url, :with => URI::regexp(%w(http https))

end

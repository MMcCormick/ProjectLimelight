class News < CoreObject
  attr_accessible :title, :image

  field :url

  # Denormilized:
  # CoreObject.response_to.name
  # CoreObjectShare.core_object_snippet.name
  field :title

  embeds_many :asset_images, as: :image_assignable, :class_name => 'AssetImage'

  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :minimum => 5, :maximum => 400 }
  #validates_format_of :url, :with => URI::regexp(%w(http https))

  attr_accessible :url

  def name
    self.title
  end

  def save_images(image)
    if image
      self.asset_images << AssetImage.create(image)
    end
  end

end

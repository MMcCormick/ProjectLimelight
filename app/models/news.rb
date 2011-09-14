class News < CoreObject
  attr_accessible :title, :image, :url

  field :url

  # Denormilized:
  # CoreObject.response_to.name
  # Notification.shared_object_snippet.name
  field :title

  embeds_many :asset_images, as: :image_assignable, :class_name => 'AssetImage'

  validates :title, :length => { :minimum => 5, :maximum => 100 }
  validates :content, :length => { :minimum => 5, :maximum => 400 }
  #validates_format_of :url, :with => URI::regexp(%w(http https))

  def name
    self.title
  end

  def save_images(image)
    if image
      self.asset_images << AssetImage.create(image)
    end
  end
end

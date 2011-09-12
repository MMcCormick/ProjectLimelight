class Picture < CoreObject
  attr_accessible :url, :title, :asset_image

  field :url, :type => String

  # Denormilized:
  # CoreObject.response_to.name
  # CoreObjectShare.core_object_snippet.name
  field :title, :type => String

  embeds_one :asset_image, as: :image_assignable

  validates :title, :length => { :minimum => 5, :maximum => 50 }, :presence => true
  validates_format_of :url, :with => URI::regexp(%w(http https)), :allow_nil => true

  def name
    self.title
  end

  def save_image
    self.asset_image.user_id = self.user_id
    self.asset_image.save
  end

end
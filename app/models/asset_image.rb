class AssetImage < Asset

  attr_accessible :isOriginal, :resizedTo, :width, :height, :image, :remote_image_url

  field :isOriginal
  field :resizedTo
  field :width
  field :height

  mount_uploader :image, ImageUploader

  embedded_in :image_snippet

  validates :image, :presence => true

end
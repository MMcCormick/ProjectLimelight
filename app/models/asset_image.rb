class AssetImage < Asset

  attr_accessible :image

  field :status, :default => 'Active'
  field :isDefault, :default => true

  mount_uploader :image, ImageUploader

  embedded_in :image_assignable, polymorphic: true

  validates :image, :presence => true

end
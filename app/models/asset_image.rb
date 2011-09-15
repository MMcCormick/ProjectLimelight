class AssetImage < Asset

  attr_accessible :image

  field :status, :default => 'Active'
  field :isDefault, :default => true
  field :dimensions, :default => []

  mount_uploader :image, ImageUploader

  embedded_in :image_assignable, polymorphic: true

  validates :image, :presence => true

  def has_dimensions? dimensions
    self.dimensions.include? dimensions
  end

end
class AssetImage < Asset

  attr_accessible :isOriginal, :resizedTo, :style, :width, :height, :image, :remote_image_url

  field :isOriginal
  field :resizedTo
  field :style, :default => 'default'
  field :width
  field :height

  mount_uploader :image, ImageUploader

  embedded_in :image_snippet

  validates :image, :presence => true

  def save_image(location)
    hash = ActiveSupport::SecureRandom::hex(8)+'.jpeg'
    writeOut = open("/tmp/#{hash}", "wb")
    writeOut.write(open(location).read)
    writeOut.close

    self.image.store!("/tmp/#{hash}")
  end

end
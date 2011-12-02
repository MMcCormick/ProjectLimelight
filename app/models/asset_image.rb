class AssetImage < Asset

  attr_accessible :isOriginal, :resizedTo, :mode, :width, :height, :image, :remote_image_url

  field :isOriginal
  field :resizedTo
  field :mode, :default => 'fit'
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

    if isOriginal
      img = Magick::Image::read("/tmp/#{hash}").first
      if img
        self.width = img.columns
        self.height = img.rows
      end
    end

    self.image.store!("/tmp/#{hash}")
  end

  # return width based on max dimension provided
  def calculate_width(max)
    if width == 0 || height == 0
      max
    elsif width > height
      max
    else
      max*(width/height)
    end
  end

  # return height based on max dimension provided
  def calculate_height(max)
    if width == 0 || height == 0
      max
    elsif width > height
      max*(height/width)
    else
      max
    end
  end

end
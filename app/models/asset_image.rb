require 'securerandom'

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
    hash = SecureRandom::hex(8)+'.jpeg'
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

  # return width x height based on max dimension provided
  def calculate_d(max)
    if width == 0 || height == 0
      max
    elsif width > height
      [max, (max*(height.to_f/width.to_f)).to_i]
    else
      [(max*(width.to_f/height.to_f)).to_i, max]
    end
  end

  def calculate_h(new_width)
    (1/(width.to_f/height.to_f))*new_width
  end

end
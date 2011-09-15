require 'RMagick'
include Magick

module ImageHelper
  def default_image(object, dimensions, classes='', id='')
    # TODO: WTF does object.default_image return an array with 1 object in it. Return JUST the object. This applies to ALL uses of .first below...
    image = object.default_image.first
    version = if image then image.find_version dimensions else nil end

    if version
      url = version.image_url
    else
      # Queue up to process and save this image size for future requests
      Resque.enqueue(ImageProcessor, object.class.to_s, object.id, image.id, dimensions)
      url = image.original.first.image_url
    end

    image_tag url, :width => "#{dimensions[0]}px"
  end
end
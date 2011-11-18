module ImageHelper
  def default_image_url(object, width=0, height=0, mode=:fit, createNow=false, returnObject=false)
    # make sure dimensions are integers
    dimensions = [width.to_i, height.to_i]
    image = object.default_image
    image = image.first if image.is_a? Array
    version = if image && mode != :original then image.find_version dimensions, mode else nil end

    if mode == :original
      return image && image.original ? image.original.first : nil
    elsif version
      url = returnObject ? version : version.image_url
    elsif image
      if createNow
        object.add_image_version image.id, dimensions, mode
        object.save
        image = object.default_image
        version = if image then image.find_version dimensions, mode else nil end
        url = returnObject ? version : version.image_url
      else
        # Queue up to process and save this image size for future requests
        Resque.enqueue(ImageProcessor, object.class.to_s, object.id.to_s, image.id.to_s, dimensions, mode)
        url = returnObject ? image.original.first : image.original.first.image_url
      end
    elsif object.instance_of? Topic
      url = (Rails.public_path unless Rails.env.development?)+"/assets/images/topic-default-#{dimensions[0]}-#{dimensions[1]}.gif"
    else
      return false
    end

    url
  end
end
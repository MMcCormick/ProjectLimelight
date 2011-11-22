module CoreObjectsHelper

  def core_object_url(object, type=nil)
    type = object.type unless type
    case type
      when 'Talk'
        talk_path object
      when 'Picture'
        picture_path object
      when 'Link'
        link_path object
      when 'Video'
        video_path object
    end
  end

end

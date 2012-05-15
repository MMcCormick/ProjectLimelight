module CoreObjectsHelper

  def core_object_url(object, type=nil, absolute=nil)
    type = object.type unless type
    case type
      when 'Talk'
        absolute ? talk_url(object) : talk_path(object)
      when 'Picture'
        absolute ? picture_path(object) : picture_path(object)
      when 'Link'
        absolute ? link_path(object) : link_path(object)
      when 'Video'
        absolute ? video_path(object) : video_path(object)
    end
  end

end

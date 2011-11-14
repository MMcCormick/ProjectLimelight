module CoreObjectsHelper

  def core_object_url(object)
    case object.type
      when 'Talk'
        talk_path object
      when 'Picture'
        picture_path object
      when 'News'
        news_path object
      when 'Video'
        video_path object
    end
  end

end

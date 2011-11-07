module CoreObjectsHelper

  def core_object_response_url(response)
    case response.type
      when 'Picture'
        picture_path response
      when 'News'
        news_path response
      when 'Video'
        video_path response
    end
  end

end

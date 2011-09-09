module VideosHelper

  def video_embed(video, w, h)
    case video.provider_name
      when 'YouTube'
        "<iframe width='#{w}' height='#{h}' src='http://www.youtube.com/embed/#{video.provider_video_id}' frameborder='0' allowfullscreen></iframe>".html_safe
      else
        "Embed not available.".html_safe
    end
  end

end

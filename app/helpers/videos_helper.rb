module VideosHelper

  def video_embed(video, w, h)
    case video.provider_name
      when 'YouTube'
        "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.youtube.com/embed/#{video.provider_video_id}' frameborder='0' allowfullscreen></iframe>".html_safe
      when 'Vimeo'
        "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://player.vimeo.com/video/#{video.provider_video_id}' frameborder='0' webkitAllowFullScreen allowFullScreen></iframe>".html_safe
      when 'Dailymotion'
        "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.dailymotion.com/embed/video/#{video.provider_video_id}' frameborder='0'></iframe>".html_safe
      else
        "Embed not available.".html_safe
    end
  end

end

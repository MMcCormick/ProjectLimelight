module VideosHelper

  def video_embed(source, w, h)
    case source.name
      when 'YouTube'
        "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.youtube.com/embed/#{source.video_id}?wmode=transparent' frameborder='0' allowfullscreen></iframe>".html_safe
      when 'Vimeo'
        "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://player.vimeo.com/video/#{source.video_id}' frameborder='0' webkitAllowFullScreen allowFullScreen></iframe>".html_safe
      when 'Dailymotion'
        "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.dailymotion.com/embed/video/#{source.video_id}' frameborder='0'></iframe>".html_safe
      else
        "Embed not available.".html_safe
    end
  end

end
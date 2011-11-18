module VideosHelper

  def video_embed(source, w, h)
    if source
      case source.name
        when 'YouTube'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.youtube.com/embed/#{source.video_id}?wmode=transparent' frameborder='0' allowfullscreen></iframe>".html_safe
        when 'Vimeo'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://player.vimeo.com/video/#{source.video_id}' frameborder='0' webkitAllowFullScreen allowFullScreen></iframe>".html_safe
        when 'Dailymotion'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.dailymotion.com/embed/video/#{source.video_id}' frameborder='0'></iframe>".html_safe
        else
          if source.name && source.url
            target = "<a href='#{source.url}' rel='nofollow' target='_blank'>#{source.name} - </a>"
          else
            target = ''
          end
          "<p>#{target}Embed not available.</p>".html_safe
      end
    else
      "<p>Embed not available.</p>".html_safe
    end
  end

end
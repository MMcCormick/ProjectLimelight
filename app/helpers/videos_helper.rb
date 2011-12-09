module VideosHelper

  def video_id(provider, data)
    case provider.downcase
      when 'youtube'
        video_id = data[:payload][:video][:data][:id]
      when 'vimeo'
        video_id = data[:payload][:video_id]
      when 'dailymotion'
        # TODO: Handle daily motion
        #video_id_parts = $(data.embedly.payload.html).attr('src').split('/')
        #video_id = video_id_parts[video_id_parts.length-1]
      else
        video_id = nil
    end
    video_id
  end

  def video_embed(source, w, h, provider=nil, video_id=nil)
    if source || (provider && video_id)
      provider = source.name.downcase unless provider
      video_id = source.video_id unless video_id
      case provider.downcase
        when 'youtube'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.youtube.com/embed/#{video_id}?wmode=transparent' frameborder='0' allowfullscreen></iframe>".html_safe
        when 'vimeo'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://player.vimeo.com/video/#{video_id}' frameborder='0' webkitAllowFullScreen allowFullScreen></iframe>".html_safe
        when 'dailymotion'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.dailymotion.com/embed/video/#{video_id}' frameborder='0'></iframe>".html_safe
        else
          if source && source.name && source.url
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
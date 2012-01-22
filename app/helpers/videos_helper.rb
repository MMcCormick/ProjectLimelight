module VideosHelper

  def video_id(provider, data)
    case provider.downcase
      when 'youtube'
        video_id = data[:payload][:video][:data][:id]
      when 'vimeo'
        video_id = data[:payload][:video_id]
      else
        video_id = nil
    end
    video_id
  end

  def video_embed(source, w, h, provider=nil, video_id=nil, embed_html=nil, autoplay=nil)
    if (source && source.video_id) || (provider && video_id)
      provider = source.name.downcase unless provider
      video_id = source.video_id unless video_id
      autoplay = autoplay ? '&autoplay=1' : ''
      case provider.downcase
        when 'youtube'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://www.youtube.com/embed/#{video_id}?wmode=transparent&rel=0#{autoplay}' frameborder='0' allowfullscreen></iframe>".html_safe
        when 'vimeo'
          "<iframe class='video-embed' width='#{w}' height='#{h}' src='http://player.vimeo.com/video/#{video_id}?color=ff0179#{autoplay}' frameborder='0' webkitAllowFullScreen allowFullScreen></iframe>".html_safe
        else
          if source && source.name && source.url
            target = "<a href='#{source.url}' rel='nofollow' target='_blank'>#{source.name} - </a>"
          else
            target = ''
          end
          "<p>#{target}Embed not available.</p>".html_safe
      end
    else
      if embed_html && ((embed_html =~ /width/i) != nil)
        embed_html.gsub(/(width)="\d+"/, '\1="'+w.to_s+'"').gsub(/(height)="\d+"/, '\1="'+h.to_s+'"').html_safe
      else
        "<p>Embed not available.</p>".html_safe
      end
    end
  end

end
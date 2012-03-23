class EmbedlyController < ApplicationController
  include VideosHelper
  include ImageHelper
  include ApplicationHelper
  include ActionView::Helpers::DateHelper

  def show

    url = params[:url]
    embedly_key = 'ca77b5aae56d11e0a9544040d3dc5c07'

    buffer = open("http://api.embed.ly/1/preview?key=#{embedly_key}&url=#{url}&format=json", "UserAgent" => "Ruby-Wget").read

    # convert JSON data into a hash
    result = JSON.parse(buffer)

    response = {
            :type => 'Link',
            :video => nil,
            :photo => nil,
            :images => result['images'],
            :provider_name => result['provider_name'],
            :url => result['url'],
            :title => result['title'],
            :limelight_post => nil
    }

    if result['object']
      if result['object']['type'] == 'video'
        response[:type] = 'Video'
        response[:video] = video_embed(nil, 120, 120, result['provider_name'], nil, result['object']['html'])
      elsif result['object']['type'] == 'photo'
        response[:type] = 'Picture'
        response[:photo] = result['object']['url']
      end
    end

    @post = result['url'] ? Post.where('sources.url' => result['url']).first : nil
    if @post
      response = render_to_string(:template => 'posts/show')
    end

    render json: response

  end

end

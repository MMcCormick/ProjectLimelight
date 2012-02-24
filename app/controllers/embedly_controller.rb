class EmbedlyController < ApplicationController
  include VideosHelper
  include ImageHelper
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

    post = result['url'] ? Post.where('sources.url' => result['url']).first : nil
    if post
      img = default_image_url(post, 50, 50, 'fillcropmid', true, true)
      response[:limelight_post] = {
              :id => post.id.to_s,
              :title => post.title_clean,
              :image => img ? img.image_url : nil,
              :embed => post.embed_html,
              :created_at => time_ago_in_words(post.created_at),
              :type => post._type
      }
    end

    render json: response

  end

end

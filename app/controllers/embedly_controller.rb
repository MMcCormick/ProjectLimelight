class EmbedlyController < ApplicationController
  include VideosHelper
  include ImageHelper
  include ApplicationHelper
  include ActionView::Helpers::DateHelper

  def show

    url = params[:url]

    response = {
            :type => 'Link',
            :video => nil,
            :photo => nil,
            :images => [],
            :provider_name => [],
            :url => url,
            :title => [],
            :existing => nil,
            :only_picture => false,
            :topic_suggestions => []
    }

    # check if it's an image
    str = open(url)
    if str && str.content_type.include?('image')
      response[:type] = 'Picture'
      response[:images] = [{:url => url}]
      response[:only_picture] = true
    else
      embedly_key = 'ca77b5aae56d11e0a9544040d3dc5c07'
      buffer = open("http://api.embed.ly/1/preview?key=#{embedly_key}&url=#{CGI.escape(url)}&format=json", "UserAgent" => "Ruby-Wget").read

      # convert JSON data into a hash
      result = JSON.parse(buffer)

      # clean images (discard small ones)
      clean_images = []
      result['images'].each do |i|
        if i['width'] >= 200
          clean_images << i
        end
      end

      response[:images] = clean_images
      response[:provider_name] = result['provider_name']
      response[:url] = result['url']
      response[:title] = result['title']

      if result['object']
        if result['object']['type'] == 'video'
          response[:type] = 'Video'
          response[:video] = video_embed(nil, 120, 120, result['provider_name'], nil, result['object']['html'])
        elsif result['object']['type'] == 'photo'
          response[:type] = 'Picture'
          response[:photo] = result['object']['url']
        end
      end
    end

    post = result && result['url'] ? PostMedia.where('sources.url' => result['url']).first : nil
    if post
      response[:existing] = post.to_json(:user => current_user)
    elsif !response[:only_picture]
      response[:topic_suggestions] = Topic.suggestions_by_url(result['url'], result['title'])
    end

    render :json => response

  end

end
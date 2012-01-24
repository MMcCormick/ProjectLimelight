class EmbedlyController < ApplicationController
  include VideosHelper
  include ImageHelper
  include ActionView::Helpers::DateHelper

  def show

    url = params[:url]

    embedly_api = Embedly::API.new :key => 'ca77b5aae56d11e0a9544040d3dc5c07'
    info = embedly_api.objectify :url => url
    obj = info[0].marshal_dump
    video_id = video_id(obj[:provider_name], obj)

    post = obj[:url] ? CoreObject.where('sources.url' => obj[:url]).first : nil
    if post
      img = default_image_url(post, 50, 50, 'fillcropmid', true, true)
      limelight_post = {
              :id => post.id.to_s,
              :title => post.title_clean,
              :image => img ? img.image_url : nil,
              :created_at => time_ago_in_words(post.created_at),
              :type => post._type
      }
    else
      limelight_post = nil
    end

    response = {
            :embedly => obj,
            :video_id => video_id,
            :video_html => video_embed(nil, 120, 120, obj[:provider_name], video_id, obj[:oembed][:html]),
            :limelight_post => limelight_post
    }

    render json: response

  end

end

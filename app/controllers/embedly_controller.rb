class EmbedlyController < ApplicationController
  include VideosHelper

  def show

    url = params[:url]

    embedly_api = Embedly::API.new :key => 'ca77b5aae56d11e0a9544040d3dc5c07'
    info = embedly_api.objectify :url => url
    obj = info[0].marshal_dump

    video_id = video_id(obj[:provider_name], obj)

    response = {
            :embedly => obj,
            :video_id => video_id,
            :video_html => video_embed(nil, 120, 120, obj[:provider_name], video_id)
    }

    render json: response

  end

end

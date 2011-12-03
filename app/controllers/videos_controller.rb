class VideosController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @site_style = 'narrow'
    @video = Video.find_by_encoded_id(params[:id])
    @responses = CoreObject.feed([:Talk], {'target' => 'created_at', 'order' => 'ASC'}, {:limit => 500, :response_to_id => @video.id})
    unless @video
      not_found("Video not found")
    end
  end

  def create
    @video = current_user.videos.build(params[:video])

    if @video.save
      @video.send_mention_notifications
      extras = { :type => "Video", :path => video_path(@video), :response => !!@video.response_to }
      response = build_ajax_response(:ok, nil, nil, nil, extras)
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Video could not be created", @video.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end

class VideosController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @site_style = 'narrow'
    @right_sidebar = true
    @video = Video.find_by_encoded_id(params[:id])
    @title = @video.name
    @description = @video.content_clean

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

  def disable
    video = Video.find_by_encoded_id(params[:id])
    if video
      authorize! :update, video
      video.status = "disabled"
      if video.save
        response = build_ajax_response(:ok, nil, "Video successfully disabled")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Video could not be disabled", video.errors)
        status = 500
      end
    else
      response = build_ajax_response(:error, nil, "Video could not be found")
      status = 404
    end
    render json: response, :status => status
  end

end

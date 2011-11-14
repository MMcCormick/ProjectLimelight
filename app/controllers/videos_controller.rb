class VideosController < ApplicationController
  authorize_resource

  def show
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
      response = build_ajax_response(:ok, video_path(@video), "Video was successfully created")
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Video could not be created", @video.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end

class VideosController < ApplicationController
  authorize_resource

  def show
    @video = Video.find_by_encoded_id(params[:id])
    unless @video
      not_found("Video not found")
    end
  end

  def create
    @video = current_user.videos.build(params[:video])

    respond_to do |format|
      if @video.save
        format.html { redirect_to @video }
        response = build_ajax_response(:ok, video_path(@video), "Video was successfully created")
        format.json { render json: response, status: :created }
      else
        format.html { render action: "new" }
        response = build_ajax_response(:error, nil, "Video could not be created", @video.errors)
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

end

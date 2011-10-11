class VideosController < ApplicationController
  authorize_resource

  def show
    @video = Video.find_by_encoded_id(params[:id])
    respond_to do |format|
      if @video
        format.html # show.html.erb
        format.json { render json: @video }
      else
        not_found("Video not found")
      end
    end
  end

  def create
    @video = current_user.videos.build(params[:video])

    respond_to do |format|
      if @video.save
        response = { :redirect => video_path(@video) }
        format.html { redirect_to @video, notice: 'Video was successfully created.' }
        format.json { render json: response, status: :created, location: @video }
      else
        format.html { render action: "new" }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

end

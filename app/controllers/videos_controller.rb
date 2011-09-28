class VideosController < ApplicationController

  before_filter :authenticate_user!, :except => [:show]

  def show
    @video = Video.find_by_encoded_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @video }
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
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

end

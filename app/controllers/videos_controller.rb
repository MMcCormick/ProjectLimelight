class VideosController < ApplicationController

  before_filter :authenticate_user!, :except => [:show]

  # GET /videos/1
  # GET /videos/1.json
  def show
    @video = Video.find_by_encoded_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @video }
    end
  end

  # GET /videos/new
  # GET /videos/new.json
  def new
    @video = Video.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @video }
    end
  end

  # GET /videos/1/edit
  def edit
    @video = Video.find_by_encoded_id(params[:id])

    if !has_permission?(current_user, @video, "edit")
      redirect_to :back, notice: 'You may only edit your own videos!.'
    end
  end

  # POST /videos
  # POST /videos.json
  def create
    @video = current_user.videos.build(params[:video])
    if @video.valid?
      @video.set_user_snippet(current_user)
      @video.set_mentions(params[:tagged_topics])
      @video.grant_owner(current_user.id)
    end

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

  # PUT /videos/1
  # PUT /videos/1.json
  def update
    @video = Video.find(params[:id])

    respond_to do |format|
      if @video.update_attributes(params[:video])
        format.html { redirect_to @video, notice: 'Video was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.json
  def destroy
    @video = Video.find(params[:id])
    @video.destroy

    respond_to do |format|
      format.html { redirect_to videos_url }
      format.json { head :ok }
    end
  end
end

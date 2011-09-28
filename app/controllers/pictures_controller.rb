class PicturesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  # GET /pictures
  # GET /pictures.json
  def index
    @pictures = Picture.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pictures }
    end
  end

  # GET /pictures/1
  # GET /pictures/1.json
  def show
    @picture = Picture.find_by_encoded_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @picture }
    end
  end

  # GET /pictures/new
  # GET /pictures/new.json
  def new
    @picture = Picture.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @picture }
    end
  end

  # GET /pictures/1/edit
  def edit
    @picture = Talk.find_by_encoded_id(params[:id])

    if !has_permission?(current_user, @talk, "edit")
      redirect_to :back, notice: 'You may only edit your own pictures!.'
    end
  end

  # POST /pictures
  # POST /pictures.json
  def create
    @picture = current_user.pictures.build(params[:picture])
    if @picture.valid?
      @picture.set_mentions(params[:tagged_topics])
      @picture.grant_owner(current_user.id)

      # TODO: Factor this out of the controller
      # Create/attach the news image
      image_snippet = ImageSnippet.new
      image_snippet.user_id = current_user.id
      image_snippet.add_uploaded_version(params[:picture][:asset_image], true)
      @picture.images << image_snippet
      # We must explicitly save the images so that CarrierWave stores them
      @picture.save_images
    end

    respond_to do |format|
      if @picture.save
        response = { :redirect => picture_path(@picture) }
        format.html { redirect_to @picture, notice: 'Picture was successfully created.' }
        format.json { render json: response, status: :created, location: @picture }
      else
        format.html { render action: "new" }
        format.json { render json: @picture.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pictures/1
  # PUT /pictures/1.json
  def update
    @picture = Picture.find(params[:id])

    if !has_permission?(current_user, @picture, "edit")
      redirect_to :back, notice: 'You may only edit your own pictures!.'
    end

    respond_to do |format|
      if @picture.update_attributes(params[:picture])
        format.html { redirect_to @picture, notice: 'Picture was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @picture.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pictures/1
  # DELETE /pictures/1.json
  def destroy
    @picture = Picture.find(params[:id])

    if !has_permission?(current_user, @picture, "edit")
      redirect_to :back, notice: 'You may only delete your own pictures!.'
    end

    @picture.destroy

    respond_to do |format|
      format.html { redirect_to pictures_url }
      format.json { head :ok }
    end
  end
end

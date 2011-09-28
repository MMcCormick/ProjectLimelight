class PicturesController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  def show
    @picture = Picture.find_by_encoded_id(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @picture }
    end
  end

  def create
    @picture = current_user.pictures.build(params[:picture])
    if @picture.valid?
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

end

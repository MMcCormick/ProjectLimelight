class PicturesController < ApplicationController
  load_and_authorize_resource :find_by => :find_by_encoded_id

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @picture }
    end
  end

  def create
    @picture = current_user.pictures.build(params[:picture])
    @picture.save_original_image
    @picture.save_images

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

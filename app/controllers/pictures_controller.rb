class PicturesController < ApplicationController
  authorize_resource

  def show
    @picture = Picture.find_by_encoded_id(params[:id])
    unless @picture
      not_found("Picture not found")
    end
  end

  def create
    @picture = current_user.pictures.build(params[:picture])
    @picture.save_original_image
    @picture.save_images

    respond_to do |format|
      if @picture.save
        format.html { redirect_to @picture }
        response = build_ajax_response(:ok, picture_path(@picture), "Picture was successfully created")
        format.json { render json: response, status: :created }
      else
        format.html { render action: "new" }
        response = build_ajax_response(:error, nil, "Picture could not be created", @picture.errors)
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

end

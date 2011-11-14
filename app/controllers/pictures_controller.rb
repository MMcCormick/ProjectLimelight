class PicturesController < ApplicationController
  authorize_resource

  def show
    @picture = Picture.find_by_encoded_id(params[:id])
    @responses = CoreObject.feed([:Talk], {'target' => 'created_at', 'order' => 'ASC'}, {:limit => 500, :response_to_id => @picture.id})
    unless @picture
      not_found("Picture not found")
    end
  end

  def create
    @picture = current_user.pictures.build(params[:picture])
    @picture.save_original_image
    @picture.save_images

    if @picture.save
      @picture.send_mention_notifications
      response = build_ajax_response(:ok, picture_path(@picture), "Picture was successfully created")
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Picture could not be created", @picture.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end

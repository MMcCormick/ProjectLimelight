class PicturesController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @picture = Picture.find_by_encoded_id(params[:id])
    not_found("Picture not found") unless @picture

    @site_style = 'narrow'
    @right_sidebar = true
    @title = @picture.name
    @description = @picture.content_clean

    @responses = CoreObject.feed([:Talk], {'target' => 'created_at', 'order' => 'ASC'}, {:limit => 500, :response_to_id => @picture.id})
  end

  def create
    @picture = current_user.pictures.build(params[:picture])
    @picture.save_original_image
    @picture.save_images

    if @picture.save
      @picture.send_mention_notifications
      extras = { :type => "Picture", :path => picture_path(@picture), :response => !!@picture.response_to }
      response = build_ajax_response(:ok, nil, nil, nil, extras)
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Picture could not be created", @picture.errors)
      render json: response, status: :unprocessable_entity
    end
  end

  def disable
    picture = Picture.find_by_encoded_id(params[:id])
    if picture
      authorize! :update, picture
      picture.status = "disabled"
      if picture.save
        picture.action_log_delete
        response = build_ajax_response(:ok, nil, "Picture successfully disabled")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Picture could not be disabled", picture.errors)
        status = 500
      end
    else
      response = build_ajax_response(:error, nil, "Picture could not be found")
      status = 404
    end
    render json: response, :status => status
  end
end

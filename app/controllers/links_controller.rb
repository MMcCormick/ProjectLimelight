class LinksController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @site_style = 'narrow'
    @link = Link.find_by_encoded_id(params[:id])

    @responses = CoreObject.feed([:Talk], {'target' => 'created_at', 'order' => 'ASC'}, {:limit => 500, :response_to_id => @link.id})
    unless @link
      not_found("Talk not found")
    end
  end

  def create
    @link = current_user.links.build(params[:link])
    @link.save_original_image
    @link.save_images

    if @link.save
      @link.send_mention_notifications
      extras = { :type => "Link", :path => link_path(@link), :response => @link.response_to }
      response = build_ajax_response(:ok, nil, nil, nil, extras)
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Link could not be created", @link.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end

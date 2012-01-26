class LinksController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @link = Link.find_by_encoded_id(params[:id])
    not_found("Link not found") unless @link

    @site_style = 'narrow'
    @right_sidebar = true
    @title = @link.name
    @description = @link.content_clean + " - a link on Limelight"

    @responses = CoreObject.for_show_page(@link.id)
  end

  def create
    @link = current_user.links.build(params[:link])
    @link.save_original_image
    @link.save_images

    if @link.save
      if params[:talk]
        current_user.talks.create(params[:talk].merge!({:parent_id => @link.id, :parent_type => 'Link'}))
      end

      extras = { :type => "Link", :path => link_path(@link) }
      response = build_ajax_response(:ok, nil, nil, nil, extras)
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Link could not be created", @link.errors)
      render json: response, status: :unprocessable_entity
    end
  end

  def disable
    link = Link.find_by_encoded_id(params[:id])
    if link
      authorize! :update, link
      link.status = "disabled"
      if link.save
        link.action_log_delete
        response = build_ajax_response(:ok, nil, "Link successfully disabled")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Link could not be disabled", link.errors)
        status = 500
      end
    else
      response = build_ajax_response(:error, nil, "Link could not be found")
      status = 404
    end
    render json: response, :status => status
  end
end

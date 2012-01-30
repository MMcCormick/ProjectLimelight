class TalksController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @talk = Talk.find_by_encoded_id(params[:id])
    not_found("Talk not found") unless @talk

    @site_style = 'narrow'
    @right_sidebar = true
    @title = @talk.name
    @description = @talk.content_clean
    @root = @talk.response_to ? CoreObject.find(@talk.root_id) : nil
  end

  def create
    data = params[:talk]

    if params[:talk][:parent_id]
      object = CoreObject.find(params[:talk][:parent_id])
      if object && ['Video', 'Link', 'Picture'].include?(object._type)
        data.merge!(:parent => object)
      end
    end

    @talk = current_user.talks.build(data)

    if @talk.save
      if @talk.response_to
        teaser = render_to_string :partial => "talks/teaser_list_full", :locals => { :object => @talk }
        extras = { :type => "Talk", :teaser => teaser, :response => true }
        object.expire_caches
      else
        extras = { :type => "Talk", :path => talk_path(@talk), :response => false }
      end

      if @talk.root_id
        list_response_html = render_to_string :partial => "talks/response_list", :locals => { :object => @talk }
        column_response_html = render_to_string :partial => "talks/response_column", :locals => { :object => @talk }
        Pusher["#{@talk.root_id.to_s}_list"].trigger('new_talk', {:id => @talk.root_id.to_s+'_list', :count => object ? object.response_count : nil, :html => list_response_html})
        Pusher["#{@talk.root_id.to_s}_column"].trigger('new_talk', {:id => @talk.root_id.to_s+'_column', :count => object ? object.response_count : nil, :html => column_response_html})
      end

      render json: build_ajax_response(:ok, nil, nil, nil, extras), status: :created
    else
      response = build_ajax_response(:error, nil, "Talk could not be created", @talk.errors)
      render json: response, status: :unprocessable_entity
    end
  end

  def disable
    talk = Talk.find_by_encoded_id(params[:id])
    if talk
      authorize! :update, talk
      talk.disable
      if talk.save
        talk.action_log_delete
        response = build_ajax_response(:ok, nil, "Talk successfully disabled")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Talk could not be disabled", talk.errors)
        status = 500
      end
    else
      response = build_ajax_response(:error, nil, "Talk could not be found")
      status = 404
    end
    render json: response, :status => status
  end

end

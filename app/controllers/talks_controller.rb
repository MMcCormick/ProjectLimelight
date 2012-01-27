class TalksController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @talk = Talk.find_by_encoded_id(params[:id])
    not_found("Talk not found") unless @talk

    @site_style = 'narrow'
    @right_sidebar = true
    @title = @talk.name
    @description = @talk.content_clean
  end

  def create
    @talk = current_user.talks.build(params[:talk])

    if params[:talk][:parent_id]
      object = CoreObject.find(params[:talk][:parent_id])
      if object && ['Video', 'Link', 'Picture'].include?(object._type)
        @talk.parent_id = object.id
        @talk.parent_type = object._type
      else
        @talk.parent_id = nil
      end
    end

    if @talk.save
      if @talk.parent_id
        view = 'list'
        teaser = render_to_string :partial => "talks/teaser_#{view}", :locals => { :object => @talk }
        extras = { :type => "Talk", :teaser => teaser, :response => true }
        object.expire_caches
      else
        extras = { :type => "Talk", :path => talk_path(@talk), :response => false }
      end

      if @talk.root_id
        response_html = render_to_string :partial => "talks/response_#{session[:feed_filters][:layout]}", :locals => { :object => @talk, :current_user => current_user }
        Pusher[@talk.root_id.to_s].trigger('new_talk', {:id => @talk.root_id.to_s, :count => object ? object.response_count : nil, :html => response_html})
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

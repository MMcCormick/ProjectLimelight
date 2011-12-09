class TalksController < ApplicationController
  before_filter :authenticate_user!, :only => [:create]

  def show
    @site_style = 'narrow'
    @right_sidebar = true
    @talk = Talk.find_by_encoded_id(params[:id])
    @title = @talk.name
    @description = @talk.content_clean

    unless @talk
      not_found("Talk not found")
    end
  end

  def create
    @talk = current_user.talks.build(params[:talk])

    if @talk.save
      if @talk.response_to
        view = 'list'
        object = CoreObject.find(@talk.response_to.id)
        Notification.add(object.user, :reply, true, current_user, nil, nil, true, object, object.user, nil)
        teaser = render_to_string :partial => "talks/teaser_#{view}", :locals => { :object => @talk }
        extras = { :teaser => teaser, :response => true }
        object.expire_caches
      else
        view = session[:feed_filters][:layout]
        extras = { :type => "Talk", :path => talk_path(@talk), :response => false }
      end

      @talk.send_mention_notifications
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
      talk.status = "disabled"
      if talk.save
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

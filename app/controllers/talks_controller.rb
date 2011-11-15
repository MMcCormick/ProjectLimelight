class TalksController < ApplicationController
  authorize_resource

  def show
    @talk = Talk.find_by_encoded_id(params[:id])

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
      else
        view = session[:feed_filters][:layout]
      end

      @talk.send_mention_notifications
      teaser = render_to_string :partial => "talks/teaser_#{view}", :locals => { :object => @talk }
      response = build_ajax_response(:ok, nil, "Talk was successfully created", nil, :teaser => teaser, :response => !!@talk.response_to )
      render json: response, status: :created
    else
      response = build_ajax_response(:error, nil, "Talk could not be created", @talk.errors)
      render json: response, status: :unprocessable_entity
    end
  end

end

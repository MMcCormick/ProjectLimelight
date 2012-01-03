class TopicConSugsController < ApplicationController
  before_filter :authenticate_user!

  def new
    @title = 'Moderate Topic Connections'
    @description = 'Users can suggest connections between topics, and vote on connections that have already been suggested'

    @site_style = 'narrow'
    @connections = TopicConnection.all
  end

  def create
    #TODO: authorize, check if matching suggestion already exists

    if params[:topic_con_sug][:topic1_id].blank?
      topic1 = Topic.find_untyped_or_create(params[:topic_con_sug][:topic1_name], current_user)
    else
      topic1 = Topic.find(params[:topic_con_sug][:topic1_id])
    end
    if params[:topic_con_sug][:topic2_id].blank?
      topic2 = Topic.find_untyped_or_create(params[:topic_con_sug][:topic2_name], current_user)
    else
      topic2 = Topic.find(params[:topic_con_sug][:topic2_id])
    end

    con = TopicConnection.find(params[:topic_con_sug][:con_id])

    if con
      attr = params[:topic_con_sug].merge({ :name => con.name, :reverse_name => con.reverse_name,
                                            :topic1_slug => topic1.slug, :topic2_slug => topic2.slug })
      sug = current_user.topic_con_sugs.create(attr)

      if sug.save
        response = build_ajax_response(:ok, nil, "You connection has been submitted!")
      else
        response = build_ajax_response(:error, nil, "Connection could not be saved", sug.errors)
      end
    else
      response = build_ajax_response(:error, nil, "Please select a connection")
    end

    render json: response, status: status
  end
end
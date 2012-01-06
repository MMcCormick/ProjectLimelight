class TopicConSugsController < ApplicationController
  before_filter :authenticate_user!

  def new
    @title = 'Moderate Topic Connections'
    @description = 'Users can suggest connections between topics, and vote on connections that have already been suggested'

    @site_style = 'narrow'
    @connections = TopicConnection.all
  end

  def create
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

    if !topic1.has_alias?(params[:topic_con_sug][:topic1_name]) || !topic2.has_alias?(params[:topic_con_sug][:topic2_name])
      response = build_ajax_response(:error, nil, "Please select / create topics from the drop down")
      status = 400
    else
      if con
        if current_user.role?('admin')
          pull = params[:topic_con_sug][:pull_from] == "true" ? true : false
          reverse_pull = params[:topic_con_sug][:reverse_pull_from] == "true" ? true : false
          if TopicConnection.add(con, topic1, topic2, current_user.id, {:pull => pull, :reverse_pull => reverse_pull})
            response = build_ajax_response(:ok, nil, "You connection has been saved, admin!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Connection could not be saved (admin)", topic1.errors)
            status = 422
          end
        else
          attr = params[:topic_con_sug].merge({ :name => con.name, :reverse_name => con.reverse_name,
                                                :topic1_slug => topic1.slug, :topic2_slug => topic2.slug,
                                                :topic1_id => topic1.id, :topic2_id => topic2.id })
          sug = current_user.topic_con_sugs.build(attr)
          if sug.save
            ActionConnection.create(
                    :action => 'suggest',
                    :from_id => current_user.id,
                    :to_id => con.id,
                    :from_topic => topic1.id,
                    :to_topic => topic2.id,
                    :pull_from => params[:topic_con_sug][:pull_from],
                    :reverse_pull_from => params[:topic_con_sug][:reverse_pull_from]
            )
            response = build_ajax_response(:ok, nil, "You connection has been submitted!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Connection could not be submitted", sug.errors)
            status = 422
          end
        end
      else
        response = build_ajax_response(:error, nil, "Please select two topics and a connection")
        status = 422
      end
    end

    render json: response, status: status
  end
end
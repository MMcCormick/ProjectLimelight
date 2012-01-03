class TopicConnectionsController < ApplicationController
  def create
    unless current_user.role?('admin')
      response = build_ajax_response(:error, nil, 'You are not allowed to edit this topic!')
      status = 401
    else
      connection = current_user.topic_connections.build(params[:topic_connection])

      if connection.save
        response = build_ajax_response(:ok, nil, 'Topic connection created!')
        status = 201
      else
        response = build_ajax_response(:error, nil, 'Topic could not be created!', connection.errors)
        status = 422
      end
    end

    render json: response, :status => status
  end

  def new
    @site_style = 'narrow'
    @connections = TopicConnection.where(:opposite => "")
  end

  def add
    topic1 = Topic.find(params[:connection][:topic1_id])
    authorize! :update, topic1

    original_slug = topic1.slug
    con_id = params[:connection][:sug_con_id].blank? ? params[:connection][:con_id] : params[:connection][:sug_con_id]
    connection = TopicConnection.find(con_id)

    if params[:connection][:topic2_id].blank?
      topic2 = Topic.find_untyped_or_create(params[:connection][:topic_name], current_user)
    else
      topic2 = Topic.find(params[:connection][:topic2_id])
    end

    if topic1 && topic2 && connection
      if TopicConnection.add(connection, topic1, topic2, current_user.id) && topic1.save && topic2.save
        response = build_ajax_response(:ok, (original_slug != topic1.slug) ? edit_topic_path(topic1) : nil, "Connection created!")
        status = 201
      else
        response = build_ajax_response(:error, nil, "Could not save connection", topic1.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, 'Object not found!')
      status = 404
    end

    render json: response, :status => status
  end

  def remove
    topic1 = Topic.find(params[:topic1_id])
    authorize! :update, topic1
    original_slug = topic1.slug
    connection = TopicConnection.find(params[:id])
    topic2 = Topic.find(params[:topic2_id])

    if topic1 && topic2 && connection
      TopicConnection.remove(connection, topic1, topic2)
      if topic1.save
        response = build_ajax_response(:ok, (original_slug != topic1.slug) ? edit_topic_path(topic1) : nil, "Connection removed!")
        status = 201
      else
        response = build_ajax_response(:error, nil, "Could not remove connection", topic1.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, 'Object not found!')
      status = 404
    end

    render json: response, :status => status
  end

  def toggle_primary
    # TODO: refactor to use new neo4j system
    #topic = Topic.find(params[:topic_id])
    #authorize! :update, topic
    #original_slug = topic.slug
    #snip = topic.get_types.detect { |snippet| snippet.topic_id.to_s == params[:con_topic_id] }
    #if snip
    #  snip.primary = !snip.primary
    #  topic.v += 1
    #  if topic.save
    #    response = build_ajax_response(:ok, (original_slug != topic.slug) ? edit_topic_path(topic) : nil, nil, nil,
    #                                   {:target => ".fav_"+params[:con_topic_id], :toggle_classes => ['primaryB', 'unprimaryB']})
    #    status = 201
    #  else
    #    response = build_ajax_response(:error, nil, "Could not save topic", topic.errors)
    #    status = 422
    #  end
    #else
    #  response = build_ajax_response(:error, nil, 'Connection not found!')
    #  status = 404
    #end
    #
    #render json: response, :status => status
  end
end
class TopicConnectionsController < ApplicationController

  def index
    topic = Topic.find_by_slug_id(params[:id])
    connections = Neo4j.get_topic_relationships(topic)

    render json: connections
  end

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

  def add
    topic1 = params[:topic1_id] == "0" ? Topic.find_untyped_or_create(params[:topic1_name], current_user) : Topic.find(params[:topic1_id])
    topic2 = params[:topic2_id] == "0" ? Topic.find_untyped_or_create(params[:topic2_name], current_user) : Topic.find(params[:topic2_id])

    # If type of, use Topic.type_of_id
    if params[:id] == 'pull'
      con = true
    else
      con = params[:type_of] == "true" ? TopicConnection.find(Topic.type_of_id) : TopicConnection.find(Topic.related_to_id)
    end

    if !topic1 || !topic2
      response = build_ajax_response(:error, nil, "Please select / create topics from the drop down")
      status = 400
    else
      if con
        # if admin, create connection
        if current_user.role?('admin')
          if params[:id] == 'pull'
            success = TopicConnection.add_pull(topic1, topic2)
          else
            pull = params[:pull] == "true" ? true : false
            reverse_pull = params[:reverse_pull] == "true" ? true : false
            success = TopicConnection.add(con, topic1, topic2, current_user.id, {:pull => pull, :reverse_pull => reverse_pull})
          end

          if success
            response = build_ajax_response(:ok, nil, "Your connection has been saved, admin!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Connection already exists (admin)", topic1.errors)
            status = 422
          end
        end
      else
        response = build_ajax_response(:error, nil, "Please select a connection")
        status = 422
      end
    end

    render json: response, status: status
  end

  def remove
    topic1 = Topic.find(params[:topic1_id])
    topic2 = Topic.find(params[:topic2_id])

    authorize! :update, topic1
    authorize! :update, topic2

    connection = params[:id] == 'pull' ? true : TopicConnection.find_by_slug_id(params[:id])

    if topic1 && topic2 && connection
      if params[:id] == 'pull'
        TopicConnection.remove_pull(topic1, topic2)
      else
        TopicConnection.remove(connection, topic1, topic2)
      end

      if topic1.save
        response = build_ajax_response(:ok, nil, "Connection removed!")
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

end
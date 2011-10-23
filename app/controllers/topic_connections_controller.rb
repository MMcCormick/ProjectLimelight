class TopicConnectionsController < ApplicationController
  authorize_resource

  def create
    connection = current_user.topic_connections.build(params[:topic_connection])

    if connection.save
      response = build_ajax_response(:ok, nil, 'Topic connection created!')
      status = 201
    else
      response = build_ajax_response(:error, nil, 'Topic could not be created!', connection.errors)
      status = 422
    end

    render json: response, :status => status
  end

  def new
    @connections = TopicConnection.where(:opposite => "")
  end

  def add
    topic = Topic.find(params[:topic_id])
    if cannot? :edit, topic
      response = build_ajax_response(:error, nil, 'You are not allowed to create topic connections!')
      status = 401
    else
      connection = TopicConnection.find(params[:connection][:con_id])
      con_topic = Topic.find(params[:connection][:topic_id])

        if topic && con_topic && connection
          #TODO: check if the topic already has that topic connected
          topic.add_connection(connection, con_topic, current_user)
          if topic.save && con_topic.save
            response = build_ajax_response(:ok, nil, "Connection created!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Could not save connection", topic.errors)
            status = 422
          end
        else
          response = build_ajax_response(:error, nil, 'Object not found!')
          status = 404
        end
    end

    render json: response, :status => status
  end
end
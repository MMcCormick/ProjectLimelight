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
      response = build_ajax_response(:error, nil, 'You are not allowed to edit this topic!')
      status = 401
    else
      connection = TopicConnection.find(params[:connection][:con_id])

      if params[:connection][:topic_id] == "0"
        name = params[:connection][:topic_name]
        # Checks if there is an untyped topic with an alias equal to the name
        alias_topic = Topic.where("aliases.slug" => name.to_url, "topic_connection_snippets._id" => {"$ne" => BSON::ObjectId(Topic.type_of_id)}).first
        if alias_topic
          con_topic = alias_topic
        else
          con_topic = current_user.topics.create({name: name})
        end
      else
        con_topic = Topic.find(params[:connection][:topic_id])
      end

      if topic && con_topic && connection
        if topic.add_connection(connection, con_topic, current_user.id)
          if params[:freebase_id] && con_topic.fb_id.blank?
            con_topic.fb_id = params[:freebase_id]
            con_topic.fb_mid = params[:freebase_mid]
          end
          changed = topic.v_changed?
          if topic.save && con_topic.save
            response = build_ajax_response(:ok, changed ? edit_topic_path(topic) : nil, "Connection created!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Could not save connection", topic.errors)
            status = 422
          end
        else
          response = build_ajax_response(:error, nil, "Topic already has that connection", topic.errors)
          status = 400
        end
      else
        response = build_ajax_response(:error, nil, 'Object not found!')
        status = 404
      end
    end

    render json: response, :status => status
  end

  def remove
    topic = Topic.find(params[:topic_id])
    if cannot? :edit, topic
      response = build_ajax_response(:error, nil, 'You are not allowed to edit this topic!')
      status = 401
    else
      connection = TopicConnection.find(params[:con_id])
      con_topic = Topic.find(params[:con_topic_id])

        if topic && con_topic && connection
          topic.remove_connection(connection, con_topic)
          changed = topic.v_changed?
          if topic.save && con_topic.save
            response = build_ajax_response(:ok, changed ? edit_topic_path(topic) : nil, "Connection removed!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Could not remove connection", topic.errors)
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
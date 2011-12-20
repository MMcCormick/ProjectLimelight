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
    topic = Topic.find(params[:topic_id])
    authorize! :update, topic

    original_slug = topic.slug
    con_id = params[:connection][:sug_con_id].blank? ? params[:connection][:con_id] : params[:connection][:sug_con_id]
    connection = TopicConnection.find(con_id)

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
      if topic.add_connection(connection, con_topic, current_user.id, !!params[:connection][:primary])
        if params[:freebase_id] && con_topic.fb_id.blank?
          con_topic.fb_id = params[:freebase_id]
          con_topic.fb_mid = params[:freebase_mid]
        end
        if topic.save && con_topic.save
          response = build_ajax_response(:ok, (original_slug != topic.slug) ? edit_topic_path(topic) : nil, "Connection created!")
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

    render json: response, :status => status
  end

  def remove
    topic = Topic.find(params[:topic_id])
    authorize! :update, topic
    original_slug = topic.slug
    connection = TopicConnection.find(params[:con_id])
    con_topic = Topic.find(params[:con_topic_id])

    if topic && con_topic && connection
      topic.remove_connection(connection, con_topic)
      if topic.save && con_topic.save
        response = build_ajax_response(:ok, (original_slug != topic.slug) ? edit_topic_path(topic) : nil, "Connection removed!")
        status = 201
      else
        response = build_ajax_response(:error, nil, "Could not remove connection", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, 'Object not found!')
      status = 404
    end

    render json: response, :status => status
  end

  def toggle_primary
    topic = Topic.find(params[:topic_id])
    authorize! :update, topic
    original_slug = topic.slug
    snip = topic.get_types.detect { |snippet| snippet.topic_id.to_s == params[:con_topic_id] }
    if snip
      snip.primary = !snip.primary
      topic.v += 1
      if topic.save
        response = build_ajax_response(:ok, (original_slug != topic.slug) ? edit_topic_path(topic) : nil, nil, nil,
                                       {:target => ".fav_"+params[:con_topic_id], :toggle_classes => ['primaryB', 'unprimaryB']})
        status = 201
      else
        response = build_ajax_response(:error, nil, "Could not save topic", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, 'Connection not found!')
      status = 404
    end

    render json: response, :status => status
  end
end
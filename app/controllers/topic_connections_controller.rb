class TopicConnectionsController < ApplicationController

  def index
    connections = Neo4j.get_topic_relationships(params[:id])

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
    con = params[:type_of] == "true" ? TopicConnection.find(Topic.type_of_id) : TopicConnection.find(Topic.related_to_id)

    if !topic1 || !topic2
      response = build_ajax_response(:error, nil, "Please select / create topics from the drop down")
      status = 400
    else
      if con
        # if admin, create connection
        if current_user.role?('admin')
          if params[:pull] || params[:reverse_pull]
            pulla = {}
            pulla[:pull] = params[:pull] == "true" ? true : false
            pulla[:reverse_pull] = params[:reverse_pull] == "true" ? true : false
          end
          if TopicConnection.add(con, topic1, topic2, current_user.id, pulla)
            response = build_ajax_response(:ok, nil, "Your connection has been saved, admin!")
            status = 201
          else
            response = build_ajax_response(:error, nil, "Connection already exists (admin)", topic1.errors)
            status = 422
          end
          # if non-admin, create suggestion
        else
          attr = params.merge({ :name => con.name, :reverse_name => con.reverse_name,
                                :topic1_slug => topic1.slug, :topic2_slug => topic2.slug,
                                :topic1_id => topic1.id, :topic2_id => topic2.id, :con_id => con.id,
                                :topic1_name => topic1.name, :topic2_name => topic2.name })
          sug = current_user.topic_con_sugs.build(attr)
          if sug.save
            ActionConnection.create(
                :action => 'suggest',
                :from_id => current_user.id,
                :to_id => con.id,
                :from_topic => topic1.id,
                :to_topic => topic2.id,
                :pull_from => params[:pull_from],
                :reverse_pull_from => params[:reverse_pull_from]
            )
            #topic1.expire_caches BETA REMOVE
            #topic2.expire_caches BETA REMOVE
            html = render_to_string :partial => 'teaser', :locals => { :sug => sug }
            response = build_ajax_response(:ok, nil, "Your connection has been submitted!", nil, :teaser => html)
            status = 201
          else
            response = build_ajax_response(:error, nil, "Connection could not be submitted", sug.errors)
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
    authorize! :update, topic1
    connection = TopicConnection.find(params[:connection_id])
    topic2 = Topic.find(params[:topic2_id])

    if topic1 && topic2 && connection
      TopicConnection.remove(connection, topic1, topic2)
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
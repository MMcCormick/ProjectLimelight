class TopicsController < ApplicationController
  authorize_resource :only => [:show, :edit, :update, :merge, :add_alias]
  include ImageHelper

  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    @topic = Topic.find_by_slug(params[:id])
    @title = @topic.name
    page = params[:p] ? params[:p].to_i : 1
    @more_path = topic_path @topic, :p => page + 1
    topic_ids = @topic.pull_from_ids({}).keys << @topic.id

    @core_objects = CoreObject.feed(session[:feed_filters][:display], session[:feed_filters][:sort], {
            :mentions_topics => topic_ids,
            :page => page
    })

    respond_to do |format|
      format.js {
        response = reload_feed(@core_objects, @more_path, page)
        render json: response
      }
      format.html # index.html.erb
    end
  end

  def edit
    @topic = Topic.find_by_slug(params[:id])
  end

  def update
    @topic = Topic.find_by_slug(params[:id])
    respond_to do |format|
      if @topic.update_attributes(params[:topic])
        format.html { redirect_to @topic, notice: 'Topic was successfully updated.' }
        format.json { render json: build_ajax_response(:ok, topic_path(@topic), 'Topic was successfully updated.'), :status => :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  def default_picture
    topic = Topic.find_by_slug(params[:id])
    dimensions = params[:d]
    style = params[:s]

    url = default_image_url(topic, dimensions, style, true, false)
    img = open(Rails.env.development? ? Rails.public_path+url : url)

    if img
      send_data(
        img.read,
        :disposition => 'inline'
      )
    else
      render :nothing => true, :status => 404
    end
  end

  # Update a users default picture
  def picture_update
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic
    if topic
      image = topic.add_image(current_user.id, params[:image_location])
      topic.set_default_image(image.id) if image

      if topic.save
        #expire_action :action => :default_picture, :id => current_user.encoded_id
      end
    end

    render :json => {:status => 'ok'}
  end

  def merge
    topic = Topic.find(params[:target_id])
    aliased_topic = Topic.find_by_slug(params[:id])

    unless topic.id == aliased_topic.id
      topic.merge(aliased_topic)

      if topic.save
        aliased_topic.destroy
        response = build_ajax_response(:ok, topic_path(topic), "Topics merged!")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, "You cannot merge a topic with itself!")
      status = 400
    end

    render json: response, :status => status
  end

  def add_alias
    topic = Topic.find_by_slug(params[:id])

    if topic.add_alias(params[:new_alias])
      if topic.save
        response = build_ajax_response(:ok, nil, "Alias added!")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, "The topic already has that alias!")
      status = 400
    end

    render json: response, :status => status
  end

  def freebase_lookup
    resource = Ken::Topic.get(params[:freebase_id])

    if resource
      locals = { :topic_id => params[:id] }
      locals[:ids] = Ken.session.mqlread({ :id => params[:freebase_id], :mid => nil })
      locals[:description] = resource.description
      locals[:aliases] = resource.aliases
      locals[:image_url] = "https://usercontent.googleapis.com/freebase/v1/image#{resource.id}?maxheight=1024&maxwidth=1024"
      form = render_to_string :partial => "topics/freebase_form", :locals => locals
      response = build_ajax_response(:ok, nil, "Topic found!", nil, :form => form)
      status = 200
    else
      response = build_ajax_response(:error, nil, "Could not find this topic on freebase")
      status = 500
    end
    render json: response, status: status
  end

  def freebase_update
    topic = Topic.find_by_slug(params[:id])
    topic.fb_id = params[:freebase_id]
    topic.fb_mid = params[:freebase_mid]

    if params[:use_image] && params[:image]
      topic.fb_img = true
    end
    if params[:use_summary] && params[:summary]
      topic.summary = params[:summary]
    end
    if params[:use_aliases] && params[:aliases]
      aliases = params[:aliases].split(", ")
      aliases.each do |new_alias|
        topic.add_alias(new_alias)
      end
    end

    if topic.save
      response = build_ajax_response(:ok, nil, "Topic updated!")
      status = 200
    else
      response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
      status = 422
    end
    render json: response, status: status
  end

  def followers
    @topic = Topic.find_by_slug(params[:id])
    @followers = User.where(:following_topics => @topic.id)
  end

  def connected
    @topic = Topic.find_by_slug(params[:id])
    authorize! :read, @topic
    @connections = @topic.get_connections
  end

  def hover
    @topic = Topic.find_by_slug(params[:id])
    render :partial => 'hover_tab', :topic => @topic
  end
end
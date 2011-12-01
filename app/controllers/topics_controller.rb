class TopicsController < ApplicationController
  include ImageHelper

  caches_action :default_picture, :cache_path => Proc.new { |c| "#{c.params[:id]}-#{c.params[:w]}-#{c.params[:h]}-#{c.params[:m]}" }

  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    @topic = Topic.find_by_slug(params[:id])
    authorize! :read, @topic
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
    authorize! :edit, @topic
    @connections = @topic.get_connections
  end

  def update
    @topic = Topic.find_by_slug(params[:id])
    authorize! :update, @topic
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

  def lock_slug
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic

    original_slug = topic.slug
    topic.slug = params[:slug]
    topic.slug_locked = true
    topic.v += 1

    if topic.save
      response = build_ajax_response(:ok, (original_slug != topic.slug) ? edit_topic_path(topic) : nil, "Slug locked!")
      status = 200
    else
      response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
      status = 422
    end
    render json: response, :status => status
  end

  def default_picture
    topic = Topic.find_by_slug(params[:id])

    url = default_image_url(topic, params[:w], params[:h], params[:m], true, false)
    img = open(Rails.env.development? ? Rails.public_path+url : url)

    if img
      render :text => img.read
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
      topic.fb_img = false

      if topic.save
        topic.available_dimensions.each do |dimension|
          topic.available_modes.each do |mode|
            expire_fragment("#{topic.slug}-#{dimension[0]}-#{dimension[1]}-#{mode}")
          end
        end
      end
    end

    render :json => {:status => 'ok'}
  end

  def merge
    topic = Topic.find(params[:target_id])
    authorize! :update, topic
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
    authorize! :update, topic

    if topic.update_aliases(params[:new_aliases])
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
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic

    if resource
      locals = { :topic_id => topic.id, :topic_slug => params[:id] }
      locals[:ids] = Ken.session.mqlread({ :id => params[:freebase_id], :mid => nil })
      locals[:description] = resource.description
      locals[:aliases] = resource.aliases + [resource.text]
      locals[:types] = []
      resource.types.each do |type|
        locals[:types] << {:name => type.name}.merge(Ken.session.mqlread({ :id => type.id, :mid => nil }))
      end
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
    authorize! :update, topic
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
    authorize! :read, @topic
    @followers = User.where(:following_topics => @topic.id)
  end

  def connected
    @topic = Topic.find_by_slug(params[:id])
    authorize! :read, @topic
    @connections = @topic.get_connections
  end

  def hover
    @topic = Topic.find_by_slug(params[:id])
    authorize! :read, @topic
    render :partial => 'hover_tab', :topic => @topic
  end
end
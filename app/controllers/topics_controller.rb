class TopicsController < ApplicationController
  include ImageHelper

  caches_action :default_picture, :cache_path => Proc.new { |c| "#{c.params[:id]}-#{c.params[:w]}-#{c.params[:h]}-#{c.params[:m]}" }

  def index
    @topics = Topic.all
    authorize! :manage, :all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    @topic = Topic.find_by_slug(params[:id])
    not_found("Topic not found") unless @topic
    authorize! :read, @topic

    @title = @topic.name
    @description = @topic.summary
    @right_sidebar = true
    page = params[:p] ? params[:p].to_i : 1
    @more_path = topic_path @topic, :p => page + 1
    @topic_ids = Neo4j.pull_from_ids(@topic.id.to_s).to_a

    @core_objects = CoreObject.feed(session[:feed_filters][:display], session[:feed_filters][:sort], {
            :mentions_topics => @topic_ids << @topic.id,
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

  def new
    authorize! :manage, :all
    @site_style = 'narrow'
    @right_sidebar = false
    @topic = Topic.new
    @title = "Create a Topic"
  end

  def create
    authorize! :manage, :all
    topic = current_user.topics.build(params[:topic])
    if topic.save
      tlink = render_to_string :partial => 'topics/link', :locals => { :topic => topic, :name => topic.name }
      response = build_ajax_response(:ok, nil, "Topic created!", nil, :tlink => tlink)
      status = 201
    else
      response = build_ajax_response(:error, nil, "Topic creation failed", topic.errors)
      status = 422
    end

    render json: response, status: status
  end

  def edit
    @topic = Topic.find_by_slug(params[:id])
    not_found("Topic not found") unless @topic
    authorize! :edit, @topic

    @site_style = 'narrow'
    @right_sidebar = true
    @title = "Edit '" + @topic.name + "'"
    @connections = Neo4j.get_topic_relationships(@topic.id)
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
        format.json { render json: build_ajax_response(:error, nil, 'Topic could not be updated', @topic.errors), status: :unprocessable_entity }
      end
    end
  end

  def by_health
    authorize! :manage, :all
    @site_style = 'narrow'
    @title = "Topics by Health"
    @description = "A list of all topics on the site, sorted by health and then by popularity"
    page = params[:p] ? params[:p].to_i : 1
    health = params[:h] ? params[:h].to_i : -1
    @more_path = topics_by_health_path :p => page + 1, :h => health
    per_page = 50
    health_q = (health == -1 ? {} : { :health_index => health } )
    @topics = Topic.where(health_q).order_by([[:health_index, :asc], [:pt, :desc]]).limit(per_page).skip((page - 1) * per_page)
    @more_path = nil if @topics.count(true) < per_page

    respond_to do |format|
      format.js { render json: topic_list_response("topics/health_list", @topics, @more_path), status: :ok }
      format.html
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

    url = topic.raw_image(params[:w], params[:h], params[:m])

    if Rails.env.development? && topic.fb_img != true
      img = open(url)
      send_data(
        img.read,
        :type => 'image/png',
        :disposition => 'inline'
      )
    else
      redirect_to url
      #render :nothing => true, :status => 404
    end
  end

  # Update a users default picture
  def picture_update
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic
    if topic
      image = topic.add_image(current_user.id, params[:image_location])
      topic.set_default_image(image.id) if image
      topic.update_health('image')
      topic.fb_img = false

      if topic.save
        topic.expire_caches
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

  def destroy_alias
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic

    if topic.remove_alias(params[:name])
      if topic.save
        response = build_ajax_response(:ok, nil, "Alias removed!")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, "The topic does not have that alias!")
      status = 400
    end

    render json: response, :status => status
  end

  def update_alias
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic

    ooac = params[:alias][:ooac] == 'true' ? true : false

    result = topic.update_alias(params[:alias][:id], params[:alias][:name], ooac)
    if result == true
      if topic.save
        response = build_ajax_response(:ok, nil, "Alias updated!", nil,
                                               {:target => ".ooac_"+params[:alias][:id], :toggle_classes => ['ooacB', 'unooacB']})
        status = 200
      else
        response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, result)
      status = 400
    end

    render json: response, :status => status
  end

  def add_alias
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic

    ooac = params[:alias][:ooac] ? true : false

    result = topic.add_alias(params[:alias][:name], ooac)

    if result == true
      if topic.save
        response = build_ajax_response(:ok, nil, "Alias added!")
        status = 200
      else
        response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, result)
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
      topic.update_health('image')
      topic.available_dimensions.each do |dimension|
        topic.available_modes.each do |mode|
          expire_fragment("#{topic.slug}-#{dimension[0]}-#{dimension[1]}-#{mode}")
        end
      end
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
      topic.expire_caches
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
    not_found("Topic not found") unless @topic
    authorize! :read, @topic

    @site_style = 'narrow'
    @right_sidebar = true
    @title = "Users following '" + @topic.name + "'"
    @description = "A list of all users following" + @topic.name

    page = params[:p] ? params[:p].to_i : 1
    @more_path = topic_followers_path :p => page + 1
    per_page = 50
    @followers = User.where(:following_topics => @topic.id).limit(per_page).skip((page - 1) * per_page)
    @more_path = nil if @followers.count(true) < per_page

    respond_to do |format|
      format.js { render json: user_list_response("users/std_list", @followers, @more_path), status: :ok }
      format.html
    end
  end

  def connected
    @topic = Topic.find_by_slug(params[:id])
    not_found("Topic not found") unless @topic
    authorize! :read, @topic

    @site_style = 'narrow'
    @right_sidebar = true
    @title = "Topics connected to " + @topic.name
    @description = "A list of all topics connected to" + @topic.name
    @connections = @topic.get_connections
  end

  def hover
    @topic = Topic.find_by_slug(params[:id])
    authorize! :read, @topic
    render :partial => 'hover_tab', :topic => @topic
  end

  def pull_from
    topic = Topic.find_by_slug(params[:id])
    pull_from_ids = Neo4j.pull_from_ids(topic.id.to_s).to_a
    pull_from_ids.delete(topic.id)
    pull_from_topics = Topic.where(:_id => {'$in' => pull_from_ids})
    html = render_to_string :partial => "topics/pull_from", :locals => {:topic => topic, :pull_from_ids => pull_from_ids, :pull_from_topics => pull_from_topics}
    response = build_ajax_response(:ok, nil, nil, nil, {:html => html})
    render json: response, status: 200
  end

  def mention_suggestion
    suggestions = Topic.parse_aliases(params[:text], Topic.parse_text(params[:text], false))
    response = build_ajax_response(:ok, nil, nil, nil, {:suggestions => suggestions})
    render json: response, status: 200
  end
end
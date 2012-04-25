class TopicsController < ApplicationController
  include ImageHelper

  respond_to :html, :json

  def index
    @topics = Topic.all
    if params[:sort]
      @topics = @topics.order_by(params[:sort][0], params[:sort][1])
    end

    if params[:limit] && params[:limit].to_i < 100
      @topics = @topics.limit(params[:limit])
    else
      @topics = @topics.limit(100)
    end

    if params[:page]
      @topics = @topics.skip(params[:limit].to_i * (params[:page].to_i-1))
    end

    render :json => @topics.map {|t| t.as_json}
  end

  def show
    # Doesn't use find_by_slug() because it doesn't work after Topic.unscoped (deleted topics are ignored)
    if params[:slug]
      @this = Topic.unscoped.find_by_slug(params[:slug])
    else
      @this = Topic.unscoped.find(params[:id])
    end

    not_found("Topic not found") unless @this
    authorize! :read, @this

    @title = @this.name
    @description = @this.summary

    respond_to do |format|
      format.html
      format.json { render :json => @this.to_json }
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
    @topic = Topic.find(params[:id])
    authorize! :update, @topic

    original_slug = @topic.slug
    @topic.name = params[:name] if params[:name]
    @topic.summary = params[:summary] if params[:summary]

    if @topic.save
      render json: build_ajax_response(:ok, (original_slug != @topic.slug) ? topic_path(@topic) : nil, 'Topic was successfully updated.'), :status => :ok
    else
      render json: build_ajax_response(:error, nil, 'Topic could not be updated', @topic.errors), status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :manage, :all
    if topic = Topic.find_by_slug(params[:id])
      topic.destroy
      response = build_ajax_response(:ok, nil, "Topic deleted")
      status = 200
    else
      response = build_ajax_response(:error, nil, "Topic not found")
      status = 400
    end

    render json: response, status: status
  end

  def suggestions
    @user = params[:id] ? User.find_by_slug(params[:id]) : current_user

    not_found("User not found") unless @user

    @topics = Neo4j.user_topic_suggestions(@user.id.to_s, 20)
    render 'topics/index'
  end

  def followers
    @topic = Topic.find_by_slug(params[:id])
    not_found("Topic not found") unless @topic

    @title = @topic.name + " followers"
    @description = "A list of all users who are following" + @topic.name
    followers = User.where(:following_topics => @topic.id).order_by(:slug, :asc)
    render :json => followers.map {|u| u.as_json}
  end

  def lock_slug
    topic = Topic.find(params[:id])
    authorize! :update, topic

    original_slug = topic.slug
    topic.slug = params[:slug]
    topic.slug_locked = true
    #topic.v += 1

    if topic.save
      response = build_ajax_response(:ok, (original_slug != topic.slug) ? topic_path(topic) : nil, "Slug locked!")
      status = 200
    else
      response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
      status = 422
    end
    render json: response, :status => status
  end

  def add_alias
    topic = Topic.find(params[:id])
    authorize! :update, topic

    ooac = params[:ooac] == "true" ? true : false
    result = topic.add_alias(params[:alias], ooac)

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

  def update_alias
    topic = Topic.find(params[:id])
    authorize! :update, topic

    ooac = params[:ooac] == 'true' ? true : false

    result = topic.update_alias(params[:alias_id], params[:name], ooac)
    if result == true
      if topic.save
        response = build_ajax_response(:ok, nil, "Alias updated!")
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

  def destroy_alias
    topic = Topic.find(params[:id])
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

  def update_image
    topic = Topic.find(params[:id])
    authorize! :update, topic

    if params[:url]
      topic.remote_image_url = params[:url]
      topic.save_remote_image(true)
    end

    url = topic.image_url(:fit, :large)
    render :json => build_ajax_response(:ok, nil, "Image Updated", nil, {:url => url})
  end

  def update_datasift
    topic = Topic.find(params[:id])
    authorize! :update, topic

    topic.datasift_enabled = params[:datasift_enabled] == "true" ? true : false
    topic.datasift_tags = params[:datasift_tags].split(', ')

    if topic.save
      render :json => build_ajax_response(:ok, nil, "Datasift info updated", nil), :status => 200
    else
      render :json => build_ajax_response(:error, nil, "Could not update Datasift info", nil), :status => 400
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

  def default_picture
    topic = Topic.find_by_slug(params[:id])

    url = topic.raw_image(params[:w], params[:h], params[:m])

    if Rails.env.development?
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

      if image && topic.save
        #topic.expire_caches BETA REMOVE
        topic.available_dimensions.each do |dimension|
          topic.available_modes.each do |mode|
            expire_fragment("#{topic.slug}-#{dimension[0]}-#{dimension[1]}-#{mode}")
          end
        end

        response = build_ajax_response(:ok, nil, "Topic picture updated!")
      else
        response = build_ajax_response(:error, nil, "Woops, something went wrong.")
      end
    end

    render :json => response
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

    if params[:use_summary] && params[:summary]
      topic.summary = params[:summary]
    end

    if topic.save
      #topic.expire_caches BETA REMOVE
      response = build_ajax_response(:ok, nil, "Topic updated!")
      status = 200
    else
      response = build_ajax_response(:error, nil, "Topic could not be saved", topic.errors)
      status = 422
    end
    render json: response, status: status
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

  def google_images
    topic = Topic.find_by_slug(params[:id])
    html = render_to_string :partial => "topics/google_image_rotator", :locals => {:topic => topic, :google_images => GoogleImage.all(topic.name + (topic.primary_type ? " #{topic.primary_type}" : ''), 0, request.remote_ip)}
    response = build_ajax_response(:ok, nil, nil, nil, {:html => html})
    render json: response, status: 200
  end
end
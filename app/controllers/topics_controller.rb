class TopicsController < ApplicationController
  include ImageHelper
  include ModelUtilitiesHelper

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

    @title = "All Topics"
    @description = "A list of all the topics on Limelight."

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
    @description = @this.summary ? @this.summary : "All posts about the #{@this.name} topic on Limelight."
    @og_tags = build_og_tags(@title, og_namespace+":topic", topic_url(@this), @this.image_url(:fit, :large), @description, {"#{og_namespace}:display_name" => "Topic", "#{og_namespace}:followers_count" => @this.followers_count.to_i, "#{og_namespace}:score" => @this.score.to_i, "#{og_namespace}:type" => @this.primary_type ? @this.primary_type : ''})

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
      response = build_ajax_response(:ok, nil, "Topic created!", nil)
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
    @topic = Topic.find(params[:id])
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
      topic.save
    end

    url = topic.image_url(:fit, :large)
    render :json => build_ajax_response(:ok, nil, "Image Updated", nil, {:url => url})
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
end
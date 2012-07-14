class PostsController < ApplicationController
  before_filter :authenticate_user!, :only => [:create,:edit,:update,:destroy,:disable,:stream]
  include ModelUtilitiesHelper

  respond_to :html, :json

  def index

  end

  def show
    @this = Post.find(params[:id])

    not_found("Post not found") unless @this

    media = @this.post_media
    @title = @this.media_name
    @description = @this.content
    url = post_url(:id => @this.id)
    image_url = media.image_url(:fit, :large)
    extra = {"#{og_namespace}:display_name" => @this.class.name, "#{og_namespace}:score" => @this.score.to_i}
    extra["#{og_namespace}:source"] = media.sources.first.name if media.sources && media.sources.first
    @og_tags = build_og_tags(@title, @this.og_type, url, image_url, @description, extra)

    respond_to do |format|
      format.html
      format.js { render :json => @this.to_json(:properties => :public) }
    end
  end

  def create

    @post = current_user.posts.new(params)
    #if params[:type] != 'Post' || params[:post_media_id]
    #  @post.initialize_media(params)
    #end
    #
    #if @post.valid? && (!@post.post_media_id || @post.post_media.valid?)
    #  @post.save
    #
    #  FeedUserItem.push_post_through_users(@post, current_user, false)
    #
    #  if @post.post_media
    #    @post.post_media.save
    #  end
    #
    #  track_mixpanel("New Post", current_user.mixpanel_data.merge(@post.mixpanel_data))
    #  track_mixpanel("New Post", current_user.mixpanel_data.merge(@post.post_media.mixpanel_data)) if @post.post_media_id
    #
    #  if @post.post_media_id
    #    Pusher[@post.post_media_id.to_s].trigger('new_response', @post.to_json(:properties => :public))
    #  end
    #
    #  # send mention notifications
    #  @post.user_mentions.each do |u|
    #    notification = Notification.add(u, :mention, true, current_user, nil, @post, @post.user)
    #    if notification
    #      Pusher["#{u.id.to_s}_private"].trigger('new_notification', notification.as_json)
    #    end
    #  end
    #
    #  render :json => build_ajax_response(:ok, nil, "Your post has been submitted"), :status => 201
    #else
    #  errors = @post.post_media_id ? Hash[@post.post_media.errors].merge!(Hash[@post.errors]) : @post.errors
    #  response = build_ajax_response(:error, nil, "Post could not be created", errors)
    #  render :json => response, :status => :unprocessable_entity
    #end
  end

  def new
    if signed_in?
      @url_to_post = params[:u]
    else
      session[:return_to] = request.url
    end

    render :layout => "blank_with_user"
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def disable
    post = Post.find(params[:id])
    if post
      authorize! :update, post
      post.disable
      if post.save
        post.action_log_delete
        response = build_ajax_response(:ok, nil, "#{post._type} successfully disabled")
        status = 200
      else
        response = build_ajax_response(:error, nil, "#{post._type} could not be disabled", picture.errors)
        status = 500
      end
    else
      response = build_ajax_response(:error, nil, "Post could not be found")
      status = 404
    end
    render json: response, :status => status
  end

  # a stream of all posts
  def stream
    authorize! :manage, :all

    page = params[:p] ? params[:p].to_i : 1
    posts = Post.global_stream(page)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

  # The main user feed
  def user_feed
    user = params[:id] && params[:id] != "0" ? User.find(params[:id]) : current_user
    not_found("User not found") unless user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.feed(user.id, params[:sort], page)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  # The user activity feed
  def activity_feed
    user = params[:id] && params[:id] != "0" ? User.find(params[:id]) : current_user
    not_found("User not found") unless user
    page = params[:p] ? params[:p].to_i : 1
    topic = params[:topic_id] && params[:topic_id] != "0" ? Topic.where(:slug_pretty => params[:topic_id].parameterize).first : nil
    posts = Post.activity_feed(user.id, page, topic)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  # Topic feeds...
  def topic_feed
    topic = Topic.unscoped.find(params[:id])
    not_found("Topic not found") unless topic

    page = params[:p] ? params[:p].to_i : 1
    topic_ids = Neo4j.pull_from_ids(topic.id).to_a
    posts = Post.topic_feed(topic_ids << topic.id, params[:sort], page)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  def responses
    post = Post.find(params[:id])
    not_found("Post not found") unless post
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.public_responses(post.id, page, 50)
    render :json => posts.map {|p| p.as_json(:properties => :all)}
  end

  def delete_mention
    post = Post.find(params[:id])
    not_found("Post not found") unless post

    topic = Topic.find(params[:topic_id])
    not_found("Topic not found") unless topic

    authorize! :update, post

    post.remove_topic_mention(topic)
    post.save

    render :json => build_ajax_response(:ok)
  end

  def create_mention
    post = Post.find(params[:id])
    not_found("Post not found") unless post

    authorize! :update, post

    if params[:topic_id] != '0'
      topic = Topic.find(params[:topic_id])
      not_found("Topic not found") unless topic
    else
      topic = Topic.where("aliases.slug" => params[:topic_name].parameterize, "primary_type_id" => {"$exists" => false}).first
      unless topic
        topic = current_user.topics.build({name: params[:topic_name]})
        topic.save
      end
    end

    post.add_topic_mention(topic)
    post.save

    render :json => build_ajax_response(:ok)
  end

end
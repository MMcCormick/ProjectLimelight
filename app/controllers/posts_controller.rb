class PostsController < ApplicationController

  respond_to :html, :json

  def index
  end

  def show
    if params[:encoded_id]
      @this = Post.unscoped.find_by_encoded_id(params[:id])
    else
      @this = Post.unscoped.find(params[:id])
    end

    not_found("Post not found") unless @this

    @title = @this.name
    @description = @this.content_clean

    respond_to do |format|
      format.js { render :json => @this.to_json(:user => current_user) }
      format.html
    end
  end

  def create
    @post = Post.post(params, current_user.id)

    if @post.save
      @post.save_remote_image
      if @post.response_to
        @post.bubble_up
      end

      if @post.root_id && @post.class.name == 'Talk'
        if @post.root_id
          Pusher[@post.root_id.to_s].trigger('new_response', @post.to_json(:user => current_user))
        end

        # send mention notifications
        user_ids = @post.user_mentions.map{|u| u.id}
        if user_ids.length > 0
          users = User.where(:_id => {'$in' => user_ids})
          users.each do |u|
            notification = Notification.add(u, :mention, true, current_user, nil, @post, @post.user)
            if notification
              Pusher["#{u.id.to_s}_private"].trigger('new_notification', notification.to_json)
            end
          end
        end
      end

      # send the influence pusher notification
      @post.topic_mentions.each do |mention|
        if @post.class.name == 'Talk' && mention.first_mention == true
          increase = InfluenceIncrease.new
          increase.amount = 1
          increase.topic_id = mention.id
          increase.object_type = 'Talk'
          increase.action = :new
          increase.id = mention.name
          increase.topic = mention

          Pusher[@post.user_id.to_s].trigger('influence_change', increase.to_json)
        end
      end

      render :json => build_ajax_response(:ok, nil, "Your #{@post.class.name} has been submitted"), :status => 201
    else
      response = build_ajax_response(:error, nil, "#{@post.class.name} could not be created", @post.errors)
      render :json => response, :status => :unprocessable_entity
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def disable
    post = Post.find_by_encoded_id(params[:id])
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

  # The main user feed
  def user_feed
    user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.feed(user.id, session[:feed_filters][:display], params[:sort], page)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

  # The user like feed
  def repost_feed
    user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.like_feed(user.id, session[:feed_filters][:display], page)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

  # The user activity feed
  def activity_feed
    user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.activity_feed(user.id, session[:feed_filters][:display], page)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

  # Topic feeds...
  def topic_feed
    topic = Topic.unscoped.where(slug: params[:id]).first
    not_found("Topic not found") unless topic

    page = params[:p] ? params[:p].to_i : 1
    topic_ids = Neo4j.pull_from_ids(topic.id).to_a
    posts = Post.topic_feed(topic_ids << topic.id, current_user.id, session[:feed_filters][:display], params[:sort], page)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

  # Post responses from a users friends
  def friend_responses
    post = Post.find(params[:id])
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.friend_responses(post.id, current_user, page, 50)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

  def public_responses
    post = Post.find(params[:id])
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.public_responses_no_friends(post.id, page, 50, current_user)
    render :json => posts.map {|p| p.as_json(:user => current_user)}
  end

end
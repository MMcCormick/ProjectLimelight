class PostsController < ApplicationController
  include ModelUtilitiesHelper

  respond_to :html, :json

  def index
  end

  def show
    @this = Post.find(params[:id])

    not_found("Post not found") unless @this

    @title = @this.name
    @description = @this.content
    url = @this.class.name == 'Talk' ? talk_url(:id => @this.id) : post_url(:id => @this.id)
    image_url = @this.class.name == 'Talk' ? @this.user.image_url(:fit, :large) : @this.image_url(:fit, :large)
    image_url = '' unless image_url
    extra = {"#{og_namespace}:display_name" => @this.class.name, "#{og_namespace}:score" => @this.score.to_i}
    if @this.class.name == 'talk' || @this.sources.length == 0
      extra["#{og_namespace}:source"] = @this.user.username
    else
      extra["#{og_namespace}:source"] = @this.sources.first.name
    end
    @og_tags = build_og_tags(@title, @this.og_type, url, image_url, @description, extra)

    respond_to do |format|
      format.js { render :json => @this.to_json(:properties => :public) }
      format.html
    end
  end

  def create
    @post = Post.post(params, current_user)

    if @post.save
      if @post.response_to
        @post.bubble_up
      end

      track_mixpanel("New Post", current_user.mixpanel_data.merge(@post.mixpanel_data))

      if @post.root_id && @post.class.name == 'Talk'
        if @post.root_id
          Pusher[@post.root_id.to_s].trigger('new_response', @post.to_json(:properties => :public))
        end

        # send mention notifications
        @post.user_mentions.each do |u|
          notification = Notification.add(u, :mention, true, current_user, nil, @post, @post.user)
          if notification
            Pusher["#{u.id.to_s}_private"].trigger('new_notification', notification.as_json)
          end
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

  # The user like feed
  def like_feed
    user = params[:id] && params[:id] != "0" ? User.find(params[:id]) : current_user
    not_found("User not found") unless user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.like_feed(user.id, page)
    render :json => posts.map {|p| p.as_json()}
  end

  # The user activity feed
  def activity_feed
    user = params[:id] && params[:id] != "0" ? User.find(params[:id]) : current_user
    not_found("User not found") unless user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.activity_feed(user.id, page)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  # Topic feeds...
  def topic_feed
    topic = Topic.unscoped.find(params[:id])
    not_found("Topic not found") unless topic

    page = params[:p] ? params[:p].to_i : 1
    topic_ids = Neo4j.pull_from_ids(topic.id).to_a
    posts = Post.topic_feed(topic_ids << topic.id, (signed_in? ? current_user.id : nil), params[:sort], page)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  # Post responses from a users friends
  def friend_responses
    post = Post.find(params[:id])
    not_found("Post not found") unless post
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.friend_responses(post.id, current_user, page, 50)
    render :json => posts.map {|p| p.as_json(:properties => :all)}
  end

  def public_responses
    post = Post.find(params[:id])
    not_found("Post not found") unless post
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.public_responses_no_friends(post.id, page, 50, current_user)
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
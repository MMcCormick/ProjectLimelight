class PostsController < ApplicationController

  respond_to :html, :json

  def index
  end

  def show
    @post = Post.unscoped.find_by_encoded_id(params[:id])
    not_found("Post not found") unless @post

    @site_style = 'narrow'
    @right_sidebar = true
    @title = @post.name
    @description = @post.content_clean

    @responses = Post.for_show_page(@post.id)
  end

  def create
    @post = Post.post(params, current_user.id)

    if @post.save
      if @post.response_to
        Pusher[@post.response_to.id.to_s].trigger('new_response', render_to_string(:template => 'posts/show'))
      end

      render :template => 'posts/show'
    else
      response = build_ajax_response(:error, nil, "#{@post.class.name} could not be created", @post.errors)
      render json: response, status: :unprocessable_entity
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
    user_id = params[:id] && params[:id] != "0" ? params[:id] : current_user.id.to_s
    page = params[:p] ? params[:p].to_i : 1
    @posts = Post.feed(user_id, session[:feed_filters][:display], session[:feed_filters][:sort], page)
  end

  # Topic feeds...
  def topic_feed
    page = params[:p] ? params[:p].to_i : 1
    topic_ids = Neo4j.pull_from_ids(params[:id]).to_a
    @posts = Post.topic_feed(topic_ids << params[:id], current_user.id, session[:feed_filters][:display], session[:feed_filters][:sort], page)
  end

  # Post responses from a users friends
  def friend_responses
    @posts = Post.friend_responses(params[:id], current_user)
    render :template => 'posts/responses'
  end

  def public_responses

  end

end
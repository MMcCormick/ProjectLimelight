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
      extras = { :type => @post.class.name }
      response = build_ajax_response(:ok, nil, nil, nil, extras)
      render json: response, status: :created
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

end
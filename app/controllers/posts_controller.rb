class PostsController < ApplicationController
  before_filter :authenticate_user!, :only => [:create,:edit,:update,:destroy,:disable,:stream]
  include ModelUtilitiesHelper

  respond_to :html, :json

  def index
    if params[:user_id]
      user = User.find_by_slug_id(params[:user_id])
      @posts = PostMedia.where("shares.user_id" => user.id)
    elsif params[:topic_id]
      topic = Topic.find_by_slug_id(params[:topic_id])
      topic_ids = Neo4j.pull_from_ids(topic.id.to_s).to_a
      @posts = PostMedia.where(:topic_ids => {"$in" => topic_ids << topic.id}).limit(20)
    else
      @posts = PostMedia.all.limit(20)
    end

    @posts = @posts.skip(20*(params[:page].to_i-1)) if params[:page]

    data = @posts.map do |p|
      response = p.to_json(:properties => :public)
      if params[:user_id]
        response = Yajl::Parser.parse(response)
        response['share'] = p.get_share(user.id)
        response = Yajl::Encoder.encode(response)
      end
      response
    end

    render :json => data
  end

  def show
    @this = PostMedia.find(params[:id])

    not_found("Post not found") unless @this

    @title = @this.title
    @description = @this.description
    url = post_url(:id => @this.id)
    image_url = @this.image_url(:fit, :large)
    extra = {"#{og_namespace}:display_name" => @this.class.name}
    extra["#{og_namespace}:source"] = @this.primary_source
    @og_tags = build_og_tags(@title, @this.og_type, url, image_url, @description, extra)

    respond_to do |format|
      format.html
      format.js { render :json => @this.to_json(:properties => :public) }
    end
  end

  def create

    if params[:post_id] && !params[:post_id].blank?
      @post = PostMedia.find(params[:post_id])
    else
      params[:type] = params[:type] && ['Link','Picture','Video'].include?(params[:type]) ? params[:type] : 'Link'
      @post = Kernel.const_get(params[:type]).new(params)
      @post.user_id = current_user.id
    end

    if @post

      if @post.get_share(current_user.id)
        response = build_ajax_response(:error, nil, nil, {:duplicate => 'You have already shared this post!'})
        render :json => response, :status => :unprocessable_entity
      else

        if params[:content] && !params[:content].blank?
          comment = @post.add_comment(current_user.id, params[:content])
        else
          comment = nil
        end

        if !comment || comment.valid?
          @share = @post.add_share(current_user.id, params[:content], params[:topic_mention_ids], params[:topic_mention_names], {}, !params[:from_bookmarklet].blank?)

          if @post.valid?
            @post.save

            track_mixpanel("New Share", current_user.mixpanel_data.merge(@post.mixpanel_data).merge(@share.mixpanel_data))

            FeedUserItem.push_post_through_users(@post, current_user, current_user)

            render :json => build_ajax_response(:ok, nil, "Shared Post Successfully"), :status => 201
          else
            response = build_ajax_response(:error, nil, "Share could not be created", @post.errors)
            render :json => response, :status => :unprocessable_entity
          end
        else
          response = build_ajax_response(:error, nil, "Share could not be created", comment.errors)
          render :json => response, :status => :unprocessable_entity
        end
      end
    else
      response = build_ajax_response(:error, nil, "Hmm we couldn't find the post you are trying to share.")
      render :json => response, :status => :unprocessable_entity
    end
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
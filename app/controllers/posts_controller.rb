class PostsController < ApplicationController
  before_filter :authenticate_user!, :only => [:create,:edit,:update,:destroy,:disable,:stream,:publish_share,:discard_share]
  include ModelUtilitiesHelper

  respond_to :html, :json

  def index

    if params[:user_id]
      user = User.find_by_slug_id(params[:user_id])

      if params[:topic_id]
        topic = Topic.find_by_slug_id(params[:topic_id])
        topic_ids = Neo4j.pull_from_ids(topic.neo4j_id).to_a
        @posts = PostMedia.where("shares.user_id" => user.id, "shares.0.topic_mention_ids" => {"$in" => topic_ids << topic.id}).limit(20)
      else
        if signed_in? && (user.id == current_user.id || current_user.role?("admin"))
          @posts = PostMedia.unscoped
        else
          @posts = PostMedia
        end
        @posts = @posts.where("shares.user_id" => user.id).limit(20)
      end

    elsif params[:topic_id]

      topic = Topic.find_by_slug_id(params[:topic_id])
      topic_ids = topic ? Neo4j.pull_from_ids(topic.neo4j_id).to_a : []
      @posts = PostMedia.where(:topic_ids => {"$in" => topic_ids << topic.id}).limit(20)

    else

      @posts = PostMedia.all.limit(20)

    end

    if params[:sort] && params[:sort] == 'popularity'
      @posts = @posts.desc("score")
    else
      if params[:user_id] && params[:topic_id]
        @posts = @posts.desc("shares.0.created_at")
      else
        @posts = @posts.desc("created_at")
      end
    end

    if params[:status]
      if params[:status] && params[:status] == 'pending'
        @posts = @posts.unscoped.any_of({:status => 'pending'}, {"shares.status" => 'pending'}).desc("_id").limit(20)
      end
    end

    @posts = @posts.skip(20*(params[:page].to_i-1)) if params[:page]

    data = @posts.map do |p|
      response = p.to_json(:properties => :public)
      if params[:user_id]
        response = Yajl::Parser.parse(response)
        response['share'] = p.get_share(user.id)
        response
      elsif params[:status] && params[:status] == 'pending'
        response = Yajl::Parser.parse(response)
        response['shares'] = p.shares.where('status' => 'pending').to_a
        response
      else
        Yajl::Parser.parse(response)
      end
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
      @post = PostMedia.unscoped.find(params[:post_id])
      if @post && @post.status == "pending"
        @post.remote_image_url = params[:remote_image_url] if params[:remote_image_url]
        @post.title = params[:title]
        @post.status = "active"
      end
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
          if @post.valid?
            @share = @post.add_share(current_user.id, params[:content], params[:topic_mention_ids], params[:topic_mention_names], !params[:from_bookmarklet].blank?)
            @post.process_images if @post.status == "pending"
            @share.status = "active"
            @post.status = "active"

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

  def publish_share
    post = PostMedia.find(params[:id])
    if post

      if post.status == 'pending'
        post.title = params[:title]
      end

      if post.valid?
        share = post.get_share(current_user.id)

        if share
          share.reset_topics(params[:topic_mention_ids], params[:topic_mention_names])
          share.content = params[:comment]
        else
          share = post.add_share(current_user.id, params[:comment], params[:topic_ids], params[:topic_names])
        end
        share.status = 'active'

        post.reset_topic_ids
        post.status = 'active'
        post.save

        response = post.to_json(:properties => :public)
        response = Yajl::Parser.parse(response)
        response['share'] = Yajl::Parser.parse(share.to_json(:properties => :public))

        render :json => build_ajax_response(:ok, nil, "Shared Post Successfully", nil, nil, response), :status => 201
      else
        render :json => build_ajax_response(:error, nil, "Could not Publish Post.", post.errors, nil), :status => 400
      end
    else
      render :json => build_ajax_response(:error, nil, "Could not find post.'", nil, nil), :status => 404
    end
  end

  def discard_share
    post = PostMedia.unscoped.find(params[:id])
    if post

      post.delete_share(current_user.id)

      if post.status == 'pending' && post.shares.length == 0
        post.destroy
      else
        post.save
      end

      render :json => build_ajax_response(:ok, nil, "Share Discarded"), :status => 201

    else
      render :json => build_ajax_response(:error, nil, "Could not find post.'", nil, nil), :status => 404
    end
  end

  def publish
    authorize! :manage, :all

    post = PostMedia.unscoped.find(params[:id])
    if post
      post.title = params[:title] if params[:title]

      if post.valid?

        if params[:topic_mention_ids]
          topics = Topic.where(:_id => {"$in" => params[:topic_mention_ids]})
          topics.each do |t|
            post.topic_ids << t.id
          end
        end
        if params[:topic_mention_names]
          topics = Topic.search_or_create(params[:topic_mention_names], current_user)
          topics.each do |t|
            post.topic_ids << t.id
          end
        end
        post.topic_ids.uniq!
        post.status = 'publishing'
        post.update_shares_topics

        if params[:remote_image_url]
          post.remote_image_url = params[:remote_image_url]
          post.process_images
        end

        post.save

        # publish it sometime in the next 6 hours
        Resque.enqueue_in(rand(21600), PostPublish, post.id.to_s)

        response = post.to_json(:properties => :public)
        response = Yajl::Parser.parse(response)

        render :json => build_ajax_response(:ok, nil, "Published Scheduled Successfully", nil, nil, response), :status => 201
      else
        render :json => build_ajax_response(:error, nil, "Could not Publish Post.", post.errors, nil), :status => 400
      end
    else
      render :json => build_ajax_response(:error, nil, "Could not find post.'", nil, nil), :status => 404
    end
  end

  def destroy
    authorize! :manage, :all

    post = PostMedia.unscoped.find(params[:id])
    if post
      post.destroy
      render :json => build_ajax_response(:ok, nil, "Deleted Post Successfully", nil), :status => 201
    else
      render :json => build_ajax_response(:error, nil, "Could not find post.'", nil, nil), :status => 404
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
    user = params[:id] && params[:id] != "0" ? User.find_by_slug_id(params[:id]) : current_user
    not_found("User not found") unless user
    page = params[:p] ? params[:p].to_i : 1
    posts = Post.feed(user.id, params[:sort], page)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  # The user activity feed
  def activity_feed
    user = params[:id] && params[:id] != "0" ? User.find_by_slug_id(params[:id]) : current_user
    not_found("User not found") unless user
    page = params[:p] ? params[:p].to_i : 1
    topic = params[:topic_id] && params[:topic_id] != "0" ? Topic.where(:slug_pretty => params[:topic_id].parameterize).first : nil
    posts = Post.activity_feed(user.id, page, topic)
    render :json => posts.map {|p| p.as_json(:properties => :short)}
  end

  # Topic feeds...
  def topic_feed
    topic = Topic.find_by_slug_id(params[:id])
    not_found("Topic not found") unless topic

    page = params[:p] ? params[:p].to_i : 1
    topic_ids = Neo4j.pull_from_ids(topic.neo4j_id).to_a
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
    post = PostMedia.find(params[:id])
    not_found("Post not found") unless post

    topic = Topic.find_by_slug_id(params[:topic_id])
    not_found("Topic not found") unless topic

    authorize! :update, post

    post.topic_ids.delete(topic.id)
    post.save

    render :json => build_ajax_response(:ok)
  end

  def create_mention
    post = PostMedia.find(params[:id])
    not_found("Post not found") unless post

    authorize! :update, post

    if params[:topic_id] != '0'
      topic = Topic.find_by_slug_id(params[:topic_id])
      not_found("Topic not found") unless topic
    else
      topic = Topic.where("aliases.slug" => params[:topic_name].parameterize, "primary_type_id" => {"$exists" => false}).first
      unless topic
        topic = current_user.topics.build({name: params[:topic_name]})
        topic.save
      end
    end

    post.topic_ids << topic.id
    post.save

    render :json => build_ajax_response(:ok)
  end

end
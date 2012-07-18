class TopicsController < ApplicationController
  include ImageHelper
  include ModelUtilitiesHelper

  respond_to :html, :json

  def index
    @topics = Topic.all
    @topics = Topic.parse_filters(@topics, params)

    @title = "All Topics"
    @description = "A list of all the topics on Limelight."

    render :json => @topics.map {|t| t.as_json(:properties => :public)}
  end

  def show
    # Doesn't use find_by_slug() because it doesn't work after Topic.unscoped (deleted topics are ignored)
    if params[:slug]
      @this = Topic.where(:slug_pretty => params[:slug].parameterize).first
    else
      @this = Topic.find_by_slug_id(params[:id])
    end

    not_found("Topic not found") unless @this
    authorize! :read, @this

    @title = @this.name
    @description = @this.summary ? @this.summary : "All posts about the #{@this.name} topic on Limelight."
    @og_tags = build_og_tags(@title, og_namespace+":topic", topic_url(@this), @this.image_url(:fit, :large), @description, {"#{og_namespace}:display_name" => "Topic", "#{og_namespace}:followers_count" => @this.followers_count.to_i, "#{og_namespace}:score" => @this.score.to_i, "#{og_namespace}:type" => @this.primary_type ? @this.primary_type : ''})

    respond_to do |format|
      format.html
      format.json { render :json => @this.to_json(:properties => :public) }
    end

  end

  def children
    topic = Topic.find_by_slug_id(params[:id])
    topic_ids = Neo4j.pull_from_ids(topic.id, params[:depth] ? params[:depth] : 1).to_a
    @topics = Topic.where(:_id => {"$in" => topic_ids})
    @topics = Topic.parse_filters(@topics, params)
    render :json => @topics.map {|t| t.as_json(:properties => :public)}
  end

  def parents
    topic = Topic.find_by_slug_id(params[:id])
    topic_ids = Neo4j.pulled_from_ids(topic.id, params[:depth] ? params[:depth] : 20).to_a
    @topics = Topic.where(:_id => {"$in" => topic_ids})
    @topics = Topic.parse_filters(@topics, params)
    render :json => @topics.map {|t| t.as_json(:properties => :public)}
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
    @topic = Topic.where(:slug_pretty => params[:id].parameterize).first
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

    original_slug = @topic.slug_pretty
    @topic.name = params[:name] if params[:name]
    @topic.summary = params[:summary] if params[:summary]
    @topic.url_pretty = params[:url_pretty] if params[:url_pretty]

    if params[:primary_type_id]
      type = Topic.find(params[:primary_type_id])
      @topic.set_primary_type(type.name, type.id) if type
    end

    if @topic.save
      render json: build_ajax_response(:ok, (original_slug != @topic.slug_pretty) ? topic_path(@topic) : nil, 'Topic was successfully updated.'), :status => :ok
    else
      render json: build_ajax_response(:error, nil, 'Topic could not be updated', @topic.errors), status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :manage, :all
    if params[:id]
      topic = Topic.find(params[:id])
      not_found("Topic not found") unless topic
      topic.destroy!
    elsif params[:ids]
      topics = Topic.where(:_id => {"$in" => params[:ids]})
      merge = params[:merge] ? Topic.find(params[:merge]) : nil
      topics.each do |topic|
        if merge
          posts = Post.where(:topic_mention_ids => topic.id)
          posts.each do |p|
            p.add_topic_mention(merge)
          end
        end
        topic.destroy!
      end
    end

    render :json => build_ajax_response(:ok, nil, "Topic deleted"), :status => 200
  end

  def for_connection
    authorize! :manage, :all
    @topics = Topic.all
    @topics = Topic.parse_filters(@topics, params)
    render :json => @topics.map {|t| t.as_json(:properties => :public)}
  end

  def suggestions
    @user = params[:id] ? User.where(:username => params[:id]).first : current_user

    not_found("User not found") unless @user

    @topics = Neo4j.user_topic_suggestions(@user.id.to_s, 20)
    render 'topics/index'
  end

  def followers
    @topic = Topic.find(params[:id])
    not_found("Topic not found") unless @topic

    @title = @topic.name + " followers"
    @description = "A list of all users who are following" + @topic.name
    followers = User.where(:following_topics => @topic.id).asc(:slug)
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

    ooac = params[:ooac] && params[:ooac] == "true" ? true : false
    hidden = params[:hidden] && params[:hidden] == "true" ? true : false
    result = topic.add_alias(params[:alias], ooac, hidden)

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

    ooac = params[:ooac] && params[:ooac] == 'true' ? true : false
    hidden = params[:hidden] && params[:hidden] == 'true' ? true : false

    result = topic.update_alias(params[:alias_id], params[:name], ooac, hidden)
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
      topic.save_remote_image(params[:url], true)
      topic.save
    end

    url = topic.image_url(:fit, :large)
    render :json => build_ajax_response(:ok, nil, "Image Updated", nil, {:url => url})
  end

  def update_freebase
    topic = Topic.find(params[:id])
    not_found("Topic not found") unless topic
    authorize! :update, topic

    topic.freebase_id = nil
    topic.freebase_guid = nil
    topic.freebase_mid = params[:freebase_mid]
    text = params[:text] && params[:text] == 'true' ? true : false
    aliases = params[:aliases] && params[:aliases] == 'true' ? true : false
    primary = params[:primary_type] && params[:primary_type] == 'true' ? true : false
    images = params[:images] && params[:images] == 'true' ? true : false
    topic.freebase_repopulate(text, aliases, primary, images)

    render :json => build_ajax_response(:ok, nil, "Freebase Updated")
  end

  def delete_freebase
    topic = Topic.find(params[:id])
    not_found("Topic not found") unless topic
    authorize! :update, topic

    topic.delete_freebase
    topic.save

    render :json => build_ajax_response(:ok, nil, "Freebase Deleted")
  end

  def merge
    topic = Topic.find(params[:target_id])
    authorize! :update, topic
    aliased_topic = Topic.where(:slug_pretty => params[:id].parameterize).first

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

  def duplicates
    map    = %Q{
      function() {
        var name = this.name.toLowerCase();
        name = name.replace(/[^-a-zA-Z0-9,&\s]+/ig, '');
        name = name.replace(/-/gi, "_");
        name = name.replace(/\s/gi, "-");
        emit(name, {id: this._id});
      }
    }
    reduce = %Q{
      function(key, values) {
        var result = [];
        values.forEach(function(value) {
          result.push(value.id);
        });
        return result.join('-');
      }
    }

    @topic_groups = []

    Topic.map_reduce(map, reduce).out(:inline => 1).each do |doc|
      if doc['value'].is_a?(String)
        @topic_groups << Topic.where(:_id => {"$in" => doc['value'].split('-')}).desc(:response_count).to_a
      end
    end

    @topic_groups.sort_by! {|a| a.length}
    @topic_groups.reverse!
  end

  # return category topics
  def categories
    topics = Topic.where(:is_category => true)
    render :json => topics.map {|t| t.as_json}
  end

  def add_category
    topic = Topic.find(params[:id])
    authorize! :update, topic

    category = Topic.find(params[:category_id])

    if category
      topic.add_category(category.id)
      topic.save
      render :json => build_ajax_response(:ok, nil, "Topic Category Added")
    else
      render :json => build_ajax_response(:error, nil, "Category not found!")
    end
  end

  def top_by_category
    topics = Topic.top_by_category(15)
    render :json => topics
  end
end
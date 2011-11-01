class TopicsController < ApplicationController
  authorize_resource :only => [:show, :edit, :update]
  include ImageHelper

  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    @topic = Topic.find_by_slug(params[:id])
    @title = @topic.name
    page = params[:p] ? params[:p].to_i : 1
    @more_path = topic_path @topic, :p => page + 1
    topic_ids = @topic.pull_from_ids << @topic.id

    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :mentions_topics => topic_ids,
            :page => page
    })

    respond_to do |format|
      format.js {
        response = reload_feed(@core_objects, @more_path, page)
        render json: response
      }
      format.html # index.html.erb
    end
  end

  def edit
    @topic = Topic.find_by_slug(params[:id])
    respond_to do |format|
      html = render_to_string 'edit'
      format.json {
        response = build_ajax_response(:ok, nil, nil, nil, {:content => html})
        render json: response
      }
    end
  end

  def update
    @topic = Topic.find_by_slug(params[:id])
    respond_to do |format|
      if @topic.update_attributes(params[:topic])
        format.html { redirect_to @topic, notice: 'Topic was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  def default_picture
    topic = Topic.find_by_slug(params[:id])
    dimensions = params[:d]
    style = params[:s]

    url = default_image_url(topic, dimensions, style, true, true)

    render :text => open(url, "rb").read, :stream => true
  end

  # Update a users default picture
  def picture_update
    topic = Topic.find_by_slug(params[:id])
    authorize! :update, topic
    if topic
      image = topic.images.create(:user_id => current_user.id)
      version = AssetImage.new(:isOriginal => true)
      version.id = image.id
      version.save_image(params[:image_location])
      image.versions << version
      version.save
      topic.set_default_image(image.id)

      if topic.save
        #expire_action :action => :default_picture, :id => current_user.encoded_id
      end
    end

    render :json => {:status => 'ok'}
  end

  def followers
    @topic = Topic.find_by_slug(params[:id])
    @followers = User.where(:following_topics => @topic.id)
  end

  def connected
    @topic = Topic.find_by_slug(params[:id])
    authorize! :read, @topic
    @connections = @topic.get_connections
  end

  def hover
    @topic = Topic.find_by_slug(params[:id])
    render :partial => 'hover_tab', :topic => @topic
  end
end
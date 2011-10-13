class TopicsController < ApplicationController
  load_and_authorize_resource :find_by => :find_by_slug, :only => [:show, :edit, :update]

  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    @title = @topic.name
    page = params[:p] ? params[:p].to_i : 1
    @more_path = topic_path @topic, :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :mentions_topics => [@topic.id],
            :page => page
    })

    respond_to do |format|
      format.js {
        html =  render_to_string :partial => "core_objects/feed", :locals => { :more_path => @more_path }
        render json: { :event => "loaded_feed_page", :content => html } }
      format.html # index.html.erb
      format.json { render json: @topic }
    end
  end

  def edit
    respond_to do |format|
      html = render_to_string 'edit'
      format.json { render json: { event: :topic_edit_show, content: html } }
    end
  end

  def update
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

  def hover
    @topic = Topic.find_by_slug(params[:id])
    render :partial => 'hover_tab', :topic => @topic
  end


end

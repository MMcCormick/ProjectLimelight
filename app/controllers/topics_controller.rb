class TopicsController < ApplicationController
  load_and_authorize_resource :find_by => :find_by_slug

  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_feed_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :mentions_topics => @topic.id,
            :page => page
    })
    respond_to do |format|
      if request.xhr?
        html =  render_to_string :partial => "core_objects/feed", :locals => { :more_path => @more_path }
        format.json { render json: { :event => "loaded_feed_page", :content => html } }
      else
        format.html # show.html.erb
        format.json { render json: @topic }
      end
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
    render :partial => 'hover_tab', :topic => @topic
  end

  def autocomplete
    slug = params[:q].to_url
    matches = Topic.where(:aliases => /#{slug}/i).asc(:slug)
    response = Array.new
    matches.each do |match|
      @topic = match
      response << {name: match.name, formattedItem: render_to_string(partial: 'auto_helper')}
    end

    render json: response
  end

end

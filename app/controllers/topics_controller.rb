class TopicsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  def show
    @topic = Topic.find_by_slug(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @topic }
    end
  end

  def edit
    @topic = Topic.find_by_slug(params[:id])
    respond_to do |format|
      if !has_permission?(current_user, @topic, "edit")
        format.json { render json: { flash: { :type => :error, :message => "You don't have permissions to edit this topic" }}, status: 403 }
      else
        html = render_to_string 'edit'
        format.json { render json: { event: :topic_edit_show, content: html } }
      end
    end
  end

  def update
    @topic = Topic.find_by_slug(params[:id])

    respond_to do |format|
      if !has_permission?(current_user, @topic, "edit") && !current_user.has_role?('admin')
        format.html { redirect_to :back, notice: 'You may only edit your own topics!' }
        format.json { render json: { :status => 'error', :message => 'You may only edit your own topics!' } }
      elsif @topic.update_attributes(params[:topic])
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

  def follow_toggle
    target_topic = Topic.find(params[:id])
    if target_topic
      current_user.toggle_follow_topic(target_topic)
      current_user.save
      target_topic.save
      response = {:status => 'ok', :target => '.fol_'+target_topic.id.to_s, :toggle_classes => ['followB', 'unfollowB']}
    else
      response = {:status => 'error', :message => 'Target topic not found!'}
    end

    respond_to do |format|
      #format.html # show.html.erb
      format.json { render json: response }
    end
  end
end

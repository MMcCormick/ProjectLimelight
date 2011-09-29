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
    respond_to do |format|
      format.html # show.html.erb
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
    render :partial => 'hover_tab', :topic => @topic
  end

end

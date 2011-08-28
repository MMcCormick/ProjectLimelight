class TopicsController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  # GET /topics
  # GET /topics.json
  def index
    @topics = Topic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  # GET /topics/1
  # GET /topics/1.json
  def show
    @topic = Topic.find_by_slug(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @topic }
    end
  end

  # GET /topics/new
  # GET /topics/new.json
  def new
    @topic = Topic.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @topic }
    end
  end

  # GET /topics/1/edit
  def edit
    @topic = Topic.find_by_slug(params[:id])
  end

  # POST /topics
  # POST /topics.json
  def create
    @topic = current_user.topics.build(params[:topic])
    @topic.build_user_snippet({username: current_user.username, first_name: current_user.first_name, last_name: current_user.last_name})

    respond_to do |format|
      if @topic.save
        format.html { redirect_to @topic, notice: 'Topic was successfully created.' }
        format.json { render json: @topic, status: :created, location: @topic }
      else
        format.html { render action: "new" }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # TODO: Allow people with access (admins, others via ACL) to edit topics
  # PUT /topics/1
  # PUT /topics/1.json
  #def update
  #  @topic = Topic.find(params[:id])
  #
  #  if !is_current_user_object(@talk)
  #    redirect_to :back, notice: 'You may only edit your own topics!.'
  #  end
  #
  #  respond_to do |format|
  #    if @topic.update_attributes(params[:topic])
  #      format.html { redirect_to @topic, notice: 'Topic was successfully updated.' }
  #      format.json { head :ok }
  #    else
  #      format.html { render action: "edit" }
  #      format.json { render json: @topic.errors, status: :unprocessable_entity }
  #    end
  #  end
  #end

  # TODO: Allow people with access (admins, others via ACL) to delete topics
  # DELETE /topics/1
  # DELETE /topics/1.json
  #def destroy
  #  @topic = Topic.find(params[:id])
  #
  #  if !is_current_user_object(@talk)
  #    redirect_to :back, notice: 'You may only edit your own topics!.'
  #  end
  #
  #  @topic.delete
  #
  #  respond_to do |format|
  #    format.html { redirect_to topics_url }
  #    format.json { head :ok }
  #  end
  #end
end

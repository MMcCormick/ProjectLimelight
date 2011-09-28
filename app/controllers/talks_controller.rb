class TalksController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]

  # GET /t/1
  # GET /t/1.json
  def show
    @talk = Talk.find_by_encoded_id(params[:id])
    @title = @talk.content

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @talk }
    end
  end

  # GET /t/new
  # GET /t/new.json
  def new
    @talk = Talk.new

    respond_to do |format|
      format.html # _new.html.erb
      format.json { render json: @talk }
    end
  end

  # GET /talks/1/edit
  def edit
    @talk = Talk.find_by_encoded_id(params[:id])

    if !has_permission?(current_user, @talk, "edit")
      redirect_to :back, notice: 'You may only edit your own talk!.'
    end
  end

  # POST /t
  # POST /t.json
  def create
    @talk = current_user.talks.build(params[:talk])
    if @talk.valid?
      @talk.set_mentions(params[:tagged_topics])
      @talk.grant_owner(current_user.id)
    end

    respond_to do |format|
      if @talk.save
        response = { :redirect => talk_path(@talk) }
        format.html { redirect_to @talk, notice: 'Talk was successfully created.' }
        format.json { render json: response, status: :created,  }
      else
        format.html { render action: "new" }
        format.json { render json: @talk.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /t/1
  # PUT /t/1.json
  def update
    @talk = Talk.find(params[:id])

    if !has_permission?(current_user, @talk, "edit")
      redirect_to :back, notice: 'You may only edit your own talk!'
    end

    respond_to do |format|
      if @talk.update_attributes(params[:talk])
        format.html { redirect_to @talk, notice: 'Talk was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @talk.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /t/1
  # DELETE /t/1.json
  def destroy
    @talk = Talk.find(params[:id])

    if !has_permission?(current_user, @talk, "edit")
      redirect_to :back, notice: 'You may only delete your own talk!'
    end

    @talk.delete

    respond_to do |format|
      format.html { redirect_to @talk, notice: 'Talk successfully deleted.' }
      format.json { head :ok }
    end
  end

end

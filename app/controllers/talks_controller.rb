class TalksController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]

  def show
    @talk = Talk.find_by_encoded_id(params[:id])
    @title = @talk.content

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @talk }
    end
  end

  def create
    @talk = current_user.talks.build(params[:talk])

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

end

class TalksController < ApplicationController
  authorize_resource

  def show
    @talk = Talk.find_by_encoded_id(params[:id])
    respond_to do |format|
      if @talk
        format.html # show.html.erb
        format.json { render json: @talk }
      else
        format.html { not_found("Talk not found") }
        format.json { render json: {}, status: 404 }
      end
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

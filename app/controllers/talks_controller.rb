class TalksController < ApplicationController
  authorize_resource

  def show
    @talk = Talk.find_by_encoded_id(params[:id])

    unless @talk
      not_found("Talk not found")
    end
  end

  def create
    @talk = current_user.talks.build(params[:talk])

    respond_to do |format|
      if @talk.save
        format.html { redirect_to @talk }
        response = build_ajax_response(:ok, talk_path(@talk), "Talk was successfully created")
        format.json { render json: response, status: :created }
      else
        format.html { render action: "new" }
        response = build_ajax_response(:error, nil, "Talk could not be created", @talk.errors)
        format.json { render json: response, status: :unprocessable_entity }
      end
    end
  end

end

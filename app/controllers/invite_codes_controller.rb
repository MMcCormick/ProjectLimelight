class InviteCodesController < ApplicationController
  def create
    authorize! :manage, :all
    invite = InviteCode.new(params[:invite_code])

    if invite.save
      response = build_ajax_response(:ok, nil, "Invite Code created")
      status = 201
    else
      response = build_ajax_response(:error, nil, "Creation failed", invite.errors)
      status = 422
    end

    render json: response, status: status
  end

  def new
    authorize! :manage, :all
    @title = "Create Invite Code"
    @description = "Page where administrators can create invite codes"
  end

  def check
    invite = InviteCode.where(:code => params[:code]).first
    if invite
      if invite.usable?
        session[:invite_code] = invite.id.to_s
        track_mixpanel("Invite Code Accepted", {:code => invite.code})
        response = build_ajax_response(:ok, nil, nil, nil, :invite_code_id => invite.id.to_s)
        status = 200
      else
        error = "Sorry, that invite code has been used up"
        invite.errors.add(:invite_code, error)
        response = build_ajax_response(:error, nil, nil, invite.errors)
        status = 422
      end
    else
      error = "Sorry, that code is invalid"
      response = build_ajax_response(:error, nil, nil, {:invite_code => error})
      status = 422
    end

    respond_to do |format|
      format.html do
        if error
          flash[:error] = error
          redirect_to root_path
        else
          redirect_to root_path(:show => "register")
        end
      end
      format.js { render json: response, status: status }
    end
  end
end
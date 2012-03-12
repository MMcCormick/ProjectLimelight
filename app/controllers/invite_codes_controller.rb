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
        response = build_ajax_response(:ok, nil, "Code accpted", nil, :invite_code_id => invite.id.to_s)
        status = 200
      else
        invite.errors.add(:invite_code, "Sorry, that invite code has been used up")
        response = build_ajax_response(:error, nil, nil, invite.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, nil, {:invite_code => "Sorry, that code is invalid"})
      status = 422
    end

    render json: response, status: status
  end
end
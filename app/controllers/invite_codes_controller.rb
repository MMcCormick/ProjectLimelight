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
    invite = InviteCode.first(conditions: {:code => params[:code]})
    if invite
      if invite.usable?
        session[:invite_code] = params[:code]
        response = build_ajax_response(:ok, nil, "Code accpted")
        status = 200
      else
        invite.errors.add(:code, "has been used up")
        response = build_ajax_response(:error, nil, "Sorry, that code has been used up", invite.errors)
        status = 400
      end
    else
      response = build_ajax_response(:error, nil, "Sorry, that code is invalid")
      status = 422
    end

    render json: response, satus: status
  end
end
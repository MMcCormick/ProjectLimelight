class BetaSignupsController < ApplicationController
  def create
    signup = BetaSignup.new(params)

    if signup.save
      UserMailer.beta_signup_email(params[:email]).deliver
      UserMailer.beta_signup_email_admins(params[:email]).deliver
      track_mixpanel("Request Beta Invite", {})
      response = build_ajax_response(:ok, nil, nil)
      status = 201
    else
      response = build_ajax_response(:error, nil, "Sorry, there was an error", signup.errors)
      status = 422
    end

    render json: response, status: status
  end
end
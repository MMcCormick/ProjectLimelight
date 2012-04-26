class BetaSignupsController < ApplicationController
  def create
    signup = BetaSignup.new(params)

    if signup.save
      Resque.enqueue(BetaSignupEmail, params[:email])
      response = build_ajax_response(:ok, nil, "Thanks for signing up! We'll email you when the Beta opens!'")
      status = 201
    else
      response = build_ajax_response(:error, nil, "Sorry, there was an error", signup.errors)
      status = 422
    end

    render json: response, status: status
  end
end
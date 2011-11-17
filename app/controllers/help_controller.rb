class HelpController < ApplicationController

  def tutorial_on
    session[:tutorial] = :on

    render json: build_ajax_response(:ok, request.referer), status: 200
  end

  def tutorial_off
    session[:tutorial] = :off

    render json: build_ajax_response(:ok), status: 200
  end

end
class FeedsController < ApplicationController
  def update
    session[:feed_filters] = {
      :display => params[:display],
      :sort    => params[:sort],
      :layout  => params[:layout]
    }

    respond_to do |format|
      format.js   { render :nothing => true, :status => 204 }
      format.all  { redirect_to password_changed ? new_user_session_path : edit_user_path }
    end
  end
end

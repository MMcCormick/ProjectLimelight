class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout

  # TODO: Need to create a simple MongoDB ACL system and use that instead
  # Returns true/false depending on if the currently logged in user has permission to change the object
  def is_current_user_object(object)
    signed_in? && object.respond_to?('user') && current_user == object.user
  end

  private

  def layout
    # use ajax layout for ajax requests
    request.xhr? ? "ajax" : "application"
  end

end

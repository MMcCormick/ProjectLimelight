class ApplicationController < ActionController::Base
  protect_from_forgery

  def is_current_user_object(object)
    object.respond_to?('user') && current_user == object.user
  end

end

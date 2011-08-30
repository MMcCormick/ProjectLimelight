class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init, :set_feed_filters
  layout :layout

  # Used to display the page load time on each page
  def init
    @start_time = Time.now
  end

  def set_feed_filters
    if !session[:feed_filters]
      session[:feed_filters] =
              {
                :display => ['Talk', 'News', 'Picture', 'Video'],
                :sort => {:target => 'created_at', :order => 'DESC'},
                :layout => 'list'
              }
    end
  end

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

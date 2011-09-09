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

  def has_permission?(object, target, permission)
    object.has_role?("admin") || target.has_permission?(object.id, permission)
  end

  def is_users_page?
    if current_user.slug != params[:id] && !current_user.has_role?("admin")
      flash[:notice] = "You don't have permission to access this page!"
      redirect_to root_path
    end
  end

  private

  def layout
    # use ajax layout for ajax requests
    request.xhr? ? "ajax" : "application"
  end

end

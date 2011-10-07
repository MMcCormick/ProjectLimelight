class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init, :set_feed_filters, :set_user_time_zone
  layout :layout

  # Handle authorization exceptions
  rescue_from CanCan::AccessDenied do |exception|
    if request.xhr?
      if signed_in?
        render json: {:status => :error, :message => "You don't have permission to #{exception.action} #{exception.subject.class.to_s.pluralize}"}, :status => 403
      else
        render json: {:status => :error, :message => "You must be logged in to do that!"}, :status => 401
      end
    else
      redirect_to root_url, :alert => exception.message
    end
  end

  def is_users_page?
    if current_user.slug != params[:id] && !current_user.has_role?("admin")
      flash[:notice] = "You don't have permission to access this page!"
      redirect_to root_path
    end
  end

  # Use to throw exceptions
  def not_found(message)
    raise ActionController::RoutingError.new(message)
  end


  private

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

  def set_user_time_zone
    Time.zone = current_user.time_zone if signed_in?
  end

  def layout
    # use ajax layout for ajax requests
    request.xhr? ? "ajax" : "application"
  end

end

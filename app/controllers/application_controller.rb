class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init, :set_feed_filters, :set_user_time_zone
  layout :layout

  def authenticate_admin_user!
    unless can? :manage, :all
      redirect_to root_path
    end
  end

  # Handle authorization exceptions
  rescue_from CanCan::AccessDenied do |exception|
    if request.xhr?
      if signed_in?
        render json: {:status => :error, :message => "You don't have permission to #{exception.action} #{exception.subject.class.to_s.pluralize}"}, :status => 403
      else
        render json: {:status => :error, :message => "You must be logged in to do that!"}, :status => 401
      end
    else
      permission_denied
    end
  end

  def is_users_page?
    if current_user.slug != params[:id] && !current_user.has_role?("admin")
      flash[:notice] = "You don't have permission to access this page!"
      redirect_to root_path
    end
  end

  # Build a feed response
  def reload_feed(core_objects, more_path, page)
    html =  render_to_string :partial => "core_objects/feed", :locals => { :core_objects => core_objects, :more_path => more_path }
    response = { :status => :ok, :event => "loaded_feed_page", :content => html }
    response[:full_reload] = (page == 1 ? true : false)
    return response
  end

  # update the sidebar minimized or maximized
  def sidebar
    state = params[:state]
    if [:mini, :full].include? state.to_sym
      session[:sidebar] = state.to_sym
    end

    response = build_ajax_response(:ok, nil, nil)
    render json: response, :status => 200
  end

  # Exception Throwers

  # Not Found (404)
  def not_found(message)
    raise ActionController::RoutingError.new(message)
  end
  # Permission denied (401)
  def permission_denied
    render :file => "public/401.html", :status => :unauthorized
  end

  # Exception Handlers

  rescue_from ActionController::RoutingError do
    render :file => "public/404.html", :status => 404
  end

  # Redirect after sign in / sign up
  def after_sign_in_path_for(resource)
    user_feed_path current_user
  end
  def after_sign_up_path_for(resource)
    user_feed_path current_user
  end


  # Used to test error messages as they would be shown in production
  #protected
  #
  #def local_request?
  #  false
  #end

  def build_ajax_response(status, redirect=nil, flash=nil, errors=nil, extra=nil)
    response = {:status => status, :event => "#{params[:controller]}_#{params[:action]}"}
    response[:redirect] = redirect if redirect
    response[:flash] = flash if flash
    response[:errors] = errors if errors
    response.merge!(extra) if extra
    response
  end

  private

  # Used to display the page load time on each page
  def init
    @start_time = Time.now
  end

  def set_feed_filters
    session[:sidebar] = :full unless session[:sidebar]
    unless session[:feed_filters]
      session[:feed_filters] =
              {
                :display => ['Talk', 'News', 'Picture', 'Video'],
                :sort => {'target' => 'pd', 'order' => 'DESC'},
                :layout => 'list'
              }
    end
  end

  def set_user_time_zone
    Time.zone = current_user.time_zone if signed_in? && current_user
    Chronic.time_class = Time.zone
  end

  def layout
    # use ajax layout for ajax requests
    request.xhr? ? "ajax" : "application"
  end

end

class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :init, :set_request_type, :set_session, :set_user_time_zone#, :require_sign_in
  layout :layout

  def authenticate_admin_user!
    unless can? :manage, :all
      redirect_to root_path
    end
  end

  # Handle authorization exceptions
  rescue_from CanCan::AccessDenied do |exception|
    if signed_in?
      permission_denied(exception)
    else
      render_forbidden(exception)
    end
  end

  def is_users_page?
    if current_user.slug != params[:id] && !current_user.role?("admin")
      flash[:notice] = "You don't have permission to access this page!"
      redirect_to root_path
    end
  end

  # Build a feed response
  def reload_feed(core_objects, more_path, page)
    html =  render_to_string :partial => "core_objects/feed", :locals => { :core_objects => core_objects, :more_path => more_path }
    response = { :status => :ok, :event => "loaded_feed_page", :content => html }
    response[:full_reload] = (page == 1 ? true : false)
    response
  end

  # Build a topic list response
  def topic_list_response(partial, topics, more_path)
    html = render_to_string :partial => partial, :locals => { :topics => topics, :more_path => more_path }
    build_ajax_response(:ok, nil, nil, nil, :content => html, :event => "loaded_topic_list")
  end

  # Build a user list response
  def user_list_response(partial, users, more_path)
    html = render_to_string :partial => partial, :locals => { :users => users, :more_path => more_path }
    build_ajax_response(:ok, nil, nil, nil, :content => html, :event => "loaded_user_list")
  end

  def set_request_type
    # this fixes an IE 8 issue with refreshing page returning javascript response
    request.format = :html if request.format == "*/*"
  end

  def json?
    request.format == 'application/json'
  end

  # Exception Throwers

  # Not Found (404)
  def not_found(message)
    @site_style = 'narrow'
    raise ActionController::RoutingError.new(message)
  end
  # Permission denied (401)
  def permission_denied(exception)
    if request.xhr?
      render json: {:status => :error, :message => "You don't have permission to #{exception.action} #{exception.subject.class.to_s.pluralize}"}, :status => 403
    else
      render :file => "public/401.html", :status => :unauthorized
    end
  end
  def render_forbidden(exception)
    if request.xhr?
      render json: {:status => :error, :message => "You must be logged in to do that!"}, :status => 401
    else
      session[:post_auth_path] = request.env['PATH_INFO']
      redirect_to new_user_session_path
    end
  end

  # Exception Handlers

  rescue_from ActionController::RoutingError do
    render :file => "public/404.html", :status => 404
  end

  # Redirect after sign in / sign up
  def after_sign_in_path_for(resource)
    back_or_default_path root_path
  end

  def back_or_default_path(default)
    path = session[:return_to] ? session[:return_to] : default
    session[:return_to] = nil
    path
  end


  # Mixpanel
  def track_mixpanel(name, params)
    Resque.enqueue(MixpanelTrackEvent, name, params, request.env.select{|k,v| v.is_a?(String) || v.is_a?(Numeric) })
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

  def set_session
    unless session[:feed_filters]
      session[:feed_filters] =
              {
                :display => ['Talk', 'Link', 'Picture', 'Video'],
                :sort => 'popular',
                :layout => 'column'
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

  def require_sign_in
    if  request.get? &&
        !(["feed", "facebook", "twitter", "splash", "check", "influence_increases"].include?(params[:action]) && params[:id].blank?) &&
        params[:controller] != "confirmations" &&
        request.fullpath != "/assets" &&
        !(params[:controller] == "topics" && params[:action] == "index")
      if !signed_in?
        session[:return_to] = request.fullpath
        redirect_to (root_path)
      elsif current_user && current_user.tutorial_step != 0
        redirect_to (root_path)
      end
    end
  end

  def build_og_tags(title, type, url, image, desc, extra={})
    og_tags = []
    og_tags << ["og:title", title]
    og_tags << ["og:type", type]
    og_tags << ["og:url", url]
    og_tags << ["og:image", image]
    og_tags << ["og:description", desc]
    extra.each do |k,e|
      og_tags << [k, e]
    end
    og_tags
  end
end

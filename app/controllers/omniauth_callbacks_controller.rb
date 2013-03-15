class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

  def facebook
    @user = User.find_by_omniauth(env["omniauth.auth"], current_user, session[:invite_code], request.env)

    if @user && @user.errors.messages['base']
      flash[:error] = "There is already a user with that account!"
      redirect_to root_path
    elsif @user && @user.persisted?
      #flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "your Facebook"
      sign_in_and_redirect @user, :event => :authentication
    else
      flash[:error] = "Your invite code is invalid!"
      session["devise.facebook_data"] = env["omniauth.auth"].except('extra')
      redirect_to root_path, :show => 'login'
    end
  end

  def twitter
    @user = User.find_by_omniauth(env["omniauth.auth"], current_user, nil, request.env)

    if @user && @user.errors.messages['base']
      flash[:error] = "There is already a user with that account!"
      redirect_to root_path
    elsif @user.persisted?
      #flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "your Twitter"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.twitter_data"] = env["omniauth.auth"].except('extra')
      redirect_to root_path
    end
  end

  def failure
    set_flash_message :alert, :failure, :kind => OmniAuth::Utils.camelize(failed_strategy.name), :reason => failure_message
    redirect_to after_omniauth_failure_path_for(resource_name)
  end

  protected

  def failed_strategy
    env["omniauth.error.strategy"]
  end

  def failure_message
    exception = env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= env["omniauth.error.type"].to_s
    error.to_s.humanize if error
  end

  def after_omniauth_failure_path_for(scope)
    new_session_path(scope)
  end

  def handle_unverified_request
    true
  end

end
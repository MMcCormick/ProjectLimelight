class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def passthru
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end

  def facebook
    @user = User.find_by_omniauth(env["omniauth.auth"], current_user, session[:invite_code])

    if @user && @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "your Facebook"
      sign_in_and_redirect @user, :event => :authentication
    else
      flash[:register_fail] = "Your invite code is invalid!"
      session["devise.facebook_data"] = env["omniauth.auth"].except('extra')
      redirect_to splash_path
    end
  end

  def google_oauth2
    @user = User.find_by_omniauth(env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "your Google"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.google_oauth2_data"] = env["omniauth.auth"].except('extra')
      redirect_to splash_path
    end
  end

  def twitter
    @user = User.find_by_omniauth(env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "your Twitter"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.twitter_data"] = env["omniauth.auth"].except('extra')
      redirect_to splash_path
    end
  end
end
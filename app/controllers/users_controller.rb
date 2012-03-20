class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:settings, :update, :picture_update, :update_settings, :topic_finder]
  include ImageHelper

  respond_to :html, :json

  def show
    @user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user

    not_found("User not found") unless @user
    @title = @user.username
    @description = "Everything #{@user.username} on Limelight."
    @this = {:group => 'users', :template => 'show'}
  end

  def create
    user = User.new_with_session(params, session)
    user.invite_code_id = session[:invite_code]

    if user.save
      if user.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(:user, user)
        render json: build_ajax_response(:ok, after_sign_up_path_for(user)), status: 201
      else
        session.keys.grep(/^devise\./).each { |k| session.delete(k) }
        render json: build_ajax_response(:ok), status: 201
      end
    else
      user.clean_up_passwords if user.respond_to?(:clean_up_passwords)
      if user.errors[:invite_code_id].blank?
        render json: build_ajax_response(:error, nil, nil, user.errors), status: 422
      else
        render json: build_ajax_response(status, nil, nil, {"invite_code" => "Your invite code is invalid"}), status: 422
      end
    end
  end

  def update
    current_user.tutorial_step = params['tutorial_step'] if params['tutorial_step']
    current_user.tutorial1_step = params['tutorial1_step'] if params['tutorial1_step']
    current_user.email_comment = params[:email_comment] if params[:email_comment]
    current_user.email_mention = params[:email_mention] if params[:email_mention]
    current_user.email_follow = params[:email_follow] if params[:email_follow]

    current_user.weekly_email = params[:weekly_email] == "true" if params[:weekly_email]

    current_user.save

    render :nothing => true, status: 200
  end

  def user_influence_increases
    @user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user
    @increases = @user.influence_increases
  end

  def influence_increases
    @increases = InfluenceIncrease.influence_increases
  end

  def followers
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = (current_user.id == @user.id ? 'Your' : @user.username + "'s") + " followers"
    @description = "A list of all users who are following" + @user.username
    @followers = User.where(:following_users => @user.id).order_by(:slug, :asc)
  end

  def following_users
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = "Users " + (current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all users who are being followed by" + @user.username
    @following_users = User.where(:_id.in => @user.following_users).order_by(:slug, :asc)
  end


  def following_topics
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = "Topics " + (current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all topics " + @user.username + " follows"
    @following_topics = Topic.where(:_id.in => @user.following_topics).order_by(:name, :asc)
  end

  # Get a users main feed
  # Includes core objects created by users this user is following
  # Includes core objects liked by users this user is following
  # Includes core objects mentioning topics this user is following (unless it's an unpopular talk)
  # Includes core objects mentioning this user
  def feed
    if signed_in?
      @user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user

      not_found("User not found") unless @user

      #if current_user.id == @user.id && @user.tutorial_step.to_i != 0
      #  redirect_to user_tutorial_path
      #else
        @title = (current_user.id == @user.id ? 'Your' : @user.username+"'s") + " Feed"
      #end
    else
      @title = 'Welcome to Limelight!'
      @description = "The Limelight splash page, where users are directed to sign in"
      @show = params[:show] ? params[:show].to_sym : false

      render "splash", :layout => "blank"
    end
  end

  def settings
    @title = 'Settings'
    @description = "Here a user can edit their settings: personal info, profile picture, and notification settings"
  end






































  # BETA REMOVE
  def default_picture
    user = User.find_by_slug(params[:id])

    url = default_image_url(user, params[:w], params[:h], params[:m], true)

    if Rails.env.development?
      img = open(Rails.public_path+url)
      send_data(
        img.read,
        :type => 'image/png',
        :disposition => 'inline'
      )
    else
      redirect_to url
      #render :nothing => true, :status => 404
    end
  end

  # Update a users default picture
  def picture_update
    image = current_user.add_image(current_user.id, params[:image_location])
    current_user.set_default_image(image.id) if image
    if current_user.save
      current_user.available_dimensions.each do |dimension|
        current_user.available_modes.each do |mode|
          expire_fragment("#{current_user.slug}-#{dimension[0]}-#{dimension[1]}-#{mode}")
        end
      end
    end

    render :json => {:status => 'ok'}
  end

  def hover
    @user = User.find_by_slug(params[:id])
    render :partial => 'hover_tab', :user => @user
  end

  #moved functionality to settings
  def update_settings
    current_user.email_share = !!params[:email_share]
    current_user.email_comment = !!params[:email_comment]
    current_user.email_mention = !!params[:email_mention]
    current_user.email_follow = !!params[:email_follow]
    current_user.notify_email = params[:notify_email] == "0" ? false : true
    current_user.weekly_email = !!params[:weekly_email]

    if current_user.save
      response = build_ajax_response(:ok, nil, "Email Settings updated")
      status = 200
    else
      response = build_ajax_response(:error, nil, "Email Settings could not be updated", current_user.errors)
      status = :unprocessable_entity
    end
    render json: response, :status => status
  end

  def tutorial
    @title = 'Limelight Tutorial'

    if params[:step]
      current_user.tutorial_step = params[:step].to_i
      current_user.save
    end

    respond_to do |format|
      format.js {
        if current_user.tutorial_step == 0
          response = build_ajax_response(:ok, root_path, nil, nil, nil)
        else
          html =  render_to_string :action => "tutorial", :locals => { :current_user => current_user }
          response = build_ajax_response(:ok, nil, nil, nil, {:html => html})
        end
        render :json => response
      }
      format.html {
        if current_user.tutorial_step == 0
          redirect_to root_path
        else
          render :layout => "topic_wall"
        end
      }
    end
  end

  def topic_finder
    @site_style = 'narrow'
    @title = "Topic Finder"
    pull = params[:limit] ? params[:limit] : 16
    pull = 20 if pull > 20
    @suggestions = Neo4j.user_topic_suggestions(current_user.id.to_s, pull)

    respond_to do |format|
      format.js {
        chosen = nil
        @suggestions.each do |s|
          chosen = s unless params[:u].include?(s['id'])
        end
        if chosen
          theme = params[:theme] ? "topics/#{params[:theme]}" : "topics/card"
          html =  render_to_string :partial => theme, :locals => { :current_user => current_user, :topic => TopicSnippet.new(chosen) }
        else
          html = ''
        end
        render json: {:card => html}
      }
      format.html
    end
  end

end

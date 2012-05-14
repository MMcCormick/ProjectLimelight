class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:settings, :update, :picture_update, :update_settings, :topic_finder]
  include ImageHelper

  respond_to :html, :json

  def show
    @this = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user

    not_found("User not found") unless @this
    @title = @this.username
    @description = "Everything #{@this.username} on Limelight."

    if params[:show_og] && params[:id] != "0"
      @og_tags = build_og_tags(@title, "profile", user_url(@this), @this.image_url(:fit, :large), [["og:username", @this.username]])
    end
  end

  def create
    user = User.new_with_session(params, session)
    user.invite_code_id = session[:invite_code]
    user.origin = 'limelight'

    if user.save
      track_mixpanel("Signup", user.mixpanel_data)
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
    # Post signup tutorial updates
    if params['tutorial_step'] && current_user.tutorial_step != params['tutorial_step']
      track_mixpanel("Signup Tutorial #{current_user.tutorial_step}", current_user.mixpanel_data)
      current_user.tutorial_step = params['tutorial_step']
    end
    current_user.tutorial1_step = params['tutorial1_step'] if params['tutorial1_step']

    current_user.email_comment = params[:email_comment] if params[:email_comment]
    current_user.email_mention = params[:email_mention] if params[:email_mention]
    current_user.email_follow = params[:email_follow] if params[:email_follow]
    current_user.weekly_email = params[:weekly_email] == "true" if params[:weekly_email]

    current_user.use_fb_image = params[:use_fb_image] == "true" if params[:use_fb_image]
    current_user.auto_follow_fb = params[:auto_follow_fb] == "true" if params[:auto_follow_fb]
    current_user.auto_follow_tw = params[:auto_follow_tw] == "true" if params[:auto_follow_tw]

    current_user.username = params[:username] if params[:username]
    current_user.unread_notification_count = params[:unread_notification_count] if params[:unread_notification_count]

    if current_user.save
      response = build_ajax_response(:ok)
      status = 200
    else
      response = build_ajax_response(:error, nil, nil, current_user.errors)
      status = :unprocessable_entity
    end

    render json: response, status: status
  end

  def user_influence_increases
    @user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user
    increases = @user.influence_increases(params[:limit].to_i, params[:with_post] == "true")
    render :json => increases.map {|i| i.as_json(:user => current_user)}
  end

  def influencer_topics
    topics = Topic.where("influencers.#{params[:id]}.influencer" => true).order_by("influencers.#{params[:id]}.influence", :desc)
    render :json => topics.map { |t| InfluencerTopic.new({ :topic => t.as_json }.merge(t.influencers[params[:id]])) }, status: 200
  end

  def almost_influencer_topics
    topics = Topic.where("influencers.#{params[:id]}.influencer" => false).order_by("influencers.#{params[:id]}.offset", :asc).limit(10).to_a
    render :json => topics.map { |t| InfluencerTopic.new({ :topic => t.as_json }.merge(t.influencers[params[:id]])) }, status: 200
  end

  def influence_increases
    increases = InfluenceIncrease.influence_increases
    render :json => increases.map {|i| i.as_json}
  end

  def followers
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = (signed_in? && current_user.id == @user.id ? 'Your' : @user.username + "'s") + " followers"
    @description = "A list of all users who are following" + @user.username
    followers = User.where(:following_users => @user.id).order_by(:slug, :asc)
    render :json => followers.map {|u| u.as_json}
  end

  def following_users
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = "Users " + (signed_in? && current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all users who are being followed by" + @user.username
    following_users = User.where(:_id.in => @user.following_users).order_by(:slug, :asc)
    render :json => following_users.map {|u| u.as_json}
  end

  def following_topics
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = "Topics " + (signed_in? && current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all topics " + @user.username + " follows"
    following_topics = Topic.where(:_id.in => @user.following_topics).order_by(:name, :asc)
    render :json => following_topics.map {|u| u.as_json}
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
      render "show"
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

  def notifications
    not_found("User not found") unless current_user

    notifications = Notification.where(:user_id => current_user.id).order_by(:created_at, :desc).to_a
    render :json => notifications.map {|n| n.as_json}
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

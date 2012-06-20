class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:settings, :update, :picture_update, :update_settings, :topic_finder]
  include ModelUtilitiesHelper
  include ImageHelper

  respond_to :html, :json

  def index
    authorize! :manage, :all
    users = User.all().desc(:id)
    render :json => users.map {|u| u.as_json}
  end

  def show
    authorize! :manage, :all if params[:require_admin]

    if params[:slug]
      @this = User.where(:slug => params[:slug].parameterize).first
    else
      @this = params[:id] && params[:id] != "0" ? User.find(params[:id]) : current_user
    end

    not_found("User not found") unless @this

    if params[:show_og] && params[:id] != "0"
      @title = @this.username
      @description = "#{@this.username} on Limelight."
      @og_tags = build_og_tags(@title, "#{og_namespace}:user", user_url(@this), @this.image_url(:fit, :large), @description, {"og:username" => @this.username, "#{og_namespace}:display_name" => "User", "#{og_namespace}:followers_count" => @this.followers_count.to_i, "#{og_namespace}:score" => @this.score.to_i, "#{og_namespace}:following_users" => @this.following_users_count.to_i, "#{og_namespace}:following_topics" => @this.following_topics_count.to_i})
    end

    respond_to do |format|
      format.html
      format.js { render :json => @this.as_json(:properties => :public) }
    end
  end

  def create
    user = User.new_with_session(params, session)
    user.used_invite_code_id = BSON::ObjectId(session[:invite_code])
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
    current_user.og_follows = params[:og_follows] == "true" if params[:og_follows]
    current_user.og_likes = params[:og_likes] == "true" if params[:og_likes]

    current_user.username = params[:username] if params[:username]
    current_user.unread_notification_count = params[:unread_notification_count] if params[:unread_notification_count]

    if current_user.changed?
      if current_user.save
        response = build_ajax_response(:ok, nil, "Setting updated")
        status = 200
      else
        response = build_ajax_response(:error, nil, nil, current_user.errors)
        status = :unprocessable_entity
      end
    else
      response = build_ajax_response(:error, nil, "Setting could not be changed. Please contact support@projectlimelight.com")
      status = :unprocessable_entity
    end

    render json: response, status: status
  end

  def user_influence_increases
    @user = params[:id] && params[:id] != "0" ? User.find(params[:id]) : current_user
    not_found("User not found") unless @user
    increases = @user.influence_increases(params[:limit].to_i, params[:with_post] == "true")
    render :json => increases.map {|i| i.as_json(:user => current_user)}
  end

  def influencer_topics
    topics = Topic.where("influencers.#{params[:id]}.influencer" => true).desc("influencers.#{params[:id]}.influence")
    render :json => topics.map { |t| InfluencerTopic.new({ :topic => t.as_json }.merge(t.influencers[params[:id]])) }, status: 200
  end

  def almost_influencer_topics
    topics = Topic.where("influencers.#{params[:id]}.influencer" => false).asc("influencers.#{params[:id]}.offset").limit(10).to_a
    render :json => topics.map { |t| InfluencerTopic.new({ :topic => t.as_json }.merge(t.influencers[params[:id]])) }, status: 200
  end

  def influence_increases
    increases = InfluenceIncrease.influence_increases
    render :json => increases.map {|i| i.as_json}
  end

  def followers
    @user = User.find(params[:id])
    not_found("User not found") unless @user

    @title = (signed_in? && current_user.id == @user.id ? 'Your' : @user.username + "'s") + " followers"
    @description = "A list of all users who are following" + @user.username
    followers = User.where(:following_users => @user.id).asc(:slug)
    render :json => followers.map {|u| u.as_json}
  end

  def following_users
    @user = User.find(params[:id])
    not_found("User not found") unless @user

    @title = "Users " + (signed_in? && current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all users who are being followed by" + @user.username
    following_users = User.where(:_id.in => @user.following_users).asc(:slug)
    render :json => following_users.map {|u| u.as_json}
  end

  def following_topics
    @user = User.find(params[:id])
    not_found("User not found") unless @user

    @title = "Topics " + (signed_in? && current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all topics " + @user.username + " follows"
    following_topics = Topic.where(:_id.in => @user.following_topics).asc(:name)
    render :json => following_topics.map {|u| u.as_json}
  end

  # Get a users main feed
  # Includes core objects created by users this user is following
  # Includes core objects liked by users this user is following
  # Includes core objects mentioning topics this user is following (unless it's an unpopular talk)
  # Includes core objects mentioning this user
  def feed
    if signed_in?
      @user = params[:id] && params[:id] != "0" ? User.where(:slug => params[:id]).first : current_user

      not_found("User not found") unless @user

      #if current_user.id == @user.id && @user.tutorial_step.to_i != 0
      #  redirect_to user_tutorial_path
      #else
        @title = (current_user.id == @user.id ? 'Your' : @user.username+"'s") + " Feed"
      #end
      render "show"
    else
      @title = 'Welcome to Limelight!'
      @description = "Limelight is a real-time news and discussion platform where users follow and discuss topics with their social network."
      @show = params[:show] ? params[:show].to_sym : false
      @og_tags = build_og_tags("Limelight", "website", root_url, "http://static.p-li.me.s3.amazonaws.com/assets/images/splash-logo.png", @description)

      render "splash", :layout => "blank"
    end
  end

  def settings
    @title = 'Settings'
    @description = "Here a user can edit their settings: personal info, profile picture, and notification settings"
  end

  def notifications
    not_found("User not found") unless current_user

    notifications = Notification.where(:user_id => current_user.id).desc(:_id).limit(20).to_a

    ids = notifications.map {|n| n.id}
    if ids.length > 0
      Notification.where(:_id => {"$in" => ids}).update_all(:read => true)
    end

    render :json => notifications.map {|n| n.as_json(:properties => :public)}
  end

  def topic_activity
    user = params[:id] && params[:id] != "0" ? User.where(:slug => params[:id]).first : current_user

    not_found("User not found") unless user

    activity = user.topics_by_activity

    if params[:topic_id] && params[:topic_id] != "0"
      existing = activity.detect{|a| a[:topic].slug_pretty == params[:topic_id].parameterize}
      if existing
        activity.delete(existing)
        activity.unshift(existing)
      else
        topic = Topic.where(:slug_pretty => params[:topic_id].parameterize).first
        if topic
          count = user.topic_activity.detect{|id,count| id == params[:topic_id]}
          activity.unshift({
                  :count => count ? count : 0,
                  :topic => topic
          })
        end
      end
    end

    render :json => activity
  end

  def topic_likes
    user = params[:id] && params[:id] != "0" ? User.where(:slug => params[:id]).first : current_user

    not_found("User not found") unless user

    activity = user.topics_by_likes

    if params[:topic_id] && params[:topic_id] != "0"
      existing = activity.detect{|a| a[:topic].slug_pretty == params[:topic_id].parameterize}
      if existing
        activity.delete(existing)
        activity.unshift(existing)
      else
        topic = Topic.where(:slug_pretty => params[:topic_id].parameterize).first
        if topic
          count = user.topic_activity.detect{|id,count| id == params[:topic_id]}
          activity.unshift({
                  :count => count ? count : 0,
                  :topic => topic
          })
        end
      end
    end

    render :json => activity
  end

end

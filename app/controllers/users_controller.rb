class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:settings, :update, :picture_update, :update_settings, :topic_finder]
  include ImageHelper

  respond_to :html, :json

  caches_action :default_picture, :cache_path => Proc.new { |c| "#{c.params[:id]}-#{c.params[:w]}-#{c.params[:h]}-#{c.params[:m]}" }
  #caches_action :feed, :if => Proc.new { |c| !signed_in? }, :cache_path => Proc.new { |c| c.params }

  def show
    @user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user

    not_found("User not found") unless @user
  end

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

  def influence_increases
    @user = params[:id] && params[:id] != "0" ? User.find_by_slug(params[:id]) : current_user
    @increases = @user.influence_increases
  end

  def followers
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = (current_user.id == @user.id ? 'Your' : @user.username + "'s") + " followers"
    @description = "A list of all users who are following" + @user.username
    @followers = User.where(:following_users => @user.id)
  end

  def following_users
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @site_style = 'narrow'
    @title = "Users " + (current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all users who are being followed by" + @user.username
    @right_sidebar = true if current_user != @user
    @following_users = User.where(:_id.in => @user.following_users)

    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_following_users_path :p => page + 1
    per_page = 50
    @following_users = User.where(:_id.in => @user.following_users).limit(per_page).skip((page - 1) * per_page)
    @more_path = nil if @following_users.count(true) < per_page

    respond_to do |format|
      format.js { render json: user_list_response("users/std_list", @following_users, @more_path), status: :ok }
      format.html
    end
  end


  def following_topics
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @site_style = 'narrow'
    @title = "Topics " + (current_user.id == @user.id ? 'you are' : @user.username+' is') + " following"
    @description = "A list of all topics which are being followed by" + @user.username
    @right_sidebar = true if current_user != @user

    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_following_topics_path :p => page + 1
    per_page = 50
    @following_topics = Topic.where(:_id.in => @user.following_topics).limit(per_page).skip((page - 1) * per_page)
    @more_path = nil if @following_topics.count(true) < per_page

    respond_to do |format|
      format.js { render json: topic_list_response("topics/std_list", @following_topics, @more_path), status: :ok }
      format.html
    end
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

      if current_user.id == @user.id && @user.tutorial_step.to_i != 0
        redirect_to user_tutorial_path
      else
        @title = (current_user.id == @user.id ? 'Your' : @user.username+"'s") + " Feed"

        page = params[:p] ? params[:p].to_i : 1
        @title = (current_user.id == @user.id ? 'Your' : @user.username+"'s") + " Feed"
      end
    else
      @title = 'Welcome to Limelight!'
      @description = "The Limelight splash page, where users are directed to sign in"
      @show = params[:show] ? params[:show].to_sym : false

      render "splash", :layout => "topic_wall"
    end
  end









































  def update
    @user = User.find_by_slug(params[:id])

    if !signed_in? || @user.id != current_user.id
      redirect_to root_path
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to user_settings_path @user }
        response = build_ajax_response(:ok, user_settings_path(@user), "Settings updated!")
        format.json { render json: response, status: :created }
      else
        format.html { redirect_to user_settings_path @user }
        response = build_ajax_response(:error, nil, "Settings could not be updated", @user.errors)
        format.json { render json: response, status: :unprocessable_entity }
      end
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

  def settings
    @site_style = 'narrow'
    @title = 'Settings'
    @description = "Here a user can edit their settings: personal info, profile picture, and email notification settings"
    unless signed_in?
      redirect_to root_path
    end
  end

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

class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:settings, :update, :picture_update, :update_settings]
  include ImageHelper

  caches_action :default_picture, :cache_path => Proc.new { |c| "#{c.params[:id]}-#{c.params[:w]}-#{c.params[:h]}-#{c.params[:m]}" }

  def show
    @user = User.find_by_slug(params[:id])
    @title = @user.username + "'s contributions"
    page = params[:p] ? params[:p].to_i : 1
    @right_sidebar = true if current_user != @user
    @more_path = user_feed_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], session[:feed_filters][:sort], {
            :created_by_users => [@user.id],
            :page => page
    })
    respond_to do |format|
      format.js {
        response = reload_feed(@core_objects, @more_path, page)
        render json: response
      }
      format.html # index.html.erb
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

  def settings
    @site_style = 'narrow'
    @title = 'Settings'
    unless signed_in?
      redirect_to root_path
    end
  end

  def update_settings
    current_user.shares_email = !!params[:shares_email]
    current_user.notify_email = !!params[:notify_email]
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

  def following_users
    @site_style = 'narrow'
    @user = User.find_by_slug(params[:id])
    @title = "Users " + @user.username + " is following"
    @right_sidebar = true if current_user != @user
    @following_users = User.where(:_id.in => @user.following_users)
  end

  def followers
    @site_style = 'narrow'
    @user = User.find_by_slug(params[:id])
    @title = @user.username + "'s followers"
    @right_sidebar = true if current_user != @user
    @followers = User.where(:following_users => @user.id)
  end

  def following_topics
    @site_style = 'narrow'
    @user = User.find_by_slug(params[:id])
    @title = "Topics " + @user.username + " is following"
    @right_sidebar = true if current_user != @user
    @following_topics = Topic.where(:_id.in => @user.following_topics)
  end

  # Get a users main feed
  # Includes core objects created by users this user is following
  # Includes core objects mentioning topics this user is following
  # Includes core objects mentioning this user
  def feed
    @user = User.find_by_slug(params[:id])
    @title = @user.username + "'s feed"
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_feed_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], session[:feed_filters][:sort], {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :page => page
    })
    respond_to do |format|
      format.js {
        response = reload_feed(@core_objects, @more_path, page)
        render json: response
      }
      format.html # index.html.erb
    end
  end

end

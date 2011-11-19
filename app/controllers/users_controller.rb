class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:settings]
  include ImageHelper

  def show
    @user = User.find_by_slug(params[:id])
    page = params[:p] ? params[:p].to_i : 1
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
        response = build_ajax_response(:ok, nil, "Settings updated!")
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
    #if stale?(:etag => url)
      img = open(Rails.env.development? ? Rails.public_path+url : url)

      if img
        send_data(
          img.read,
          :disposition => 'inline'
        )
      else
        render :nothing => true, :status => 404
      end
    #end
  end

  # Update a users default picture
  def picture_update
    image = current_user.add_image(current_user.id, params[:image_location])
    current_user.set_default_image(image.id) if image
    current_user.save

    render :json => {:status => 'ok'}
  end

  def hover
    @user = User.find_by_slug(params[:id])
    render :partial => 'hover_tab', :user => @user
  end

  def settings
    unless signed_in?
      redirect_to root_path
    end
  end

  def following_users
    @user = User.find_by_slug(params[:id])
    @following_users = User.where(:_id.in => @user.following_users)
  end

  def followers
    @user = User.find_by_slug(params[:id])
    @followers = User.where(:following_users => @user.id)
  end

  def following_topics
    @user = User.find_by_slug(params[:id])
    @following_topics = Topic.where(:_id.in => @user.following_topics)
  end

  # Get a users main feed
  # Includes core objects created by users this user is following
  # Includes core objects mentioning topics this user is following
  # Includes core objects mentioning this user
  def feed
    @user = User.find_by_slug(params[:id])
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

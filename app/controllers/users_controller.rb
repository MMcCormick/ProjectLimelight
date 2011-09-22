class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:show, :following_users, :followers, :following_topics, :feed, :contributions]

  def show
    @user = User.find_by_slug(params[:id])
  end

  def hover
    @user = User.find_by_slug(params[:id])
    render :partial => 'hover_tab', :user => @user
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
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id]
    })
  end

  def contributions
    @user = User.find_by_slug(params[:id])
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :created_by_users => [@user.id],
    })
  end

end

class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:show, :following_users, :followers, :following_topics, :feed, :contributions]

  def show
    @user = User.find_by_slug(params[:id])
  end

  def follow_toggle
    target_user = User.find(params[:id])
    if target_user
      current_user.toggle_follow_user(target_user)
      current_user.save
      target_user.save
      response = {:status => 'ok', :target => '.fol_'+target_user.id.to_s, :toggle_classes => ['followB', 'unfollowB']}
    else
      response = {:status => 'error', :message => 'Target user not found!'}
    end

    respond_to do |format|
      format.json { render json: response }
    end
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

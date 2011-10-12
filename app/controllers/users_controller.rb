class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [:edit]

  def show
    @user = User.find_by_slug(params[:id])
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_feed_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :created_by_users => [@user.id],
            :page => page
    })
    respond_to do |format|
      if request.xhr?
        html =  render_to_string :partial => "core_objects/feed", :locals => { :more_path => @more_path }
        format.json { render json: { :event => "loaded_feed_page", :content => html } }
      else
        format.html
      end
    end
  end

  # Temporary, for checking callbacks
  def edit
    @user = User.find_by_slug(params[:id])
  end

  def update
    @user = User.find_by_slug(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'Topic was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
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
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_feed_path :p => page + 1
    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :page => page
    })
    respond_to do |format|
      if request.xhr?
        html =  render_to_string :partial => "core_objects/feed", :locals => { :more_path => @more_path }
        format.json { render json: { :event => "loaded_feed_page", :content => html } }
      else
        format.html
      end
    end
  end

end

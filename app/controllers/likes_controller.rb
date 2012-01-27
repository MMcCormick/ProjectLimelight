class LikesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @user = User.find_by_slug(params[:id])
    not_found("User not found") unless @user

    @title = @user.username + "'s likes"
    @description = @user.username + "'s liked posts on Limelight."
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_likes_path :p => page + 1
    @right_sidebar = true if current_user != @user

    @core_objects = CoreObject.like_feed(@user.id, session[:feed_filters][:display], session[:feed_filters][:sort], page)
    respond_to do |format|
      format.js {
        response = reload_feed(@core_objects, @more_path, page)
        render json: response
      }
      format.html # index.html.erb
    end
  end

  def create
    object = CoreObject.find(params[:id])
    if object
      like_success = object.add_to_likes(current_user)
      if like_success
        object.add_pop_action(:rp, :a, current_user)
        current_user.save if object.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.like_'+object.id.to_s, :toggle_classes => ['likeB', 'unlikeB']})
        status = 201
      elsif like_success.nil?
        response = build_ajax_response(:error, nil, 'You cannot like your own posts!')
        status = 401
      else
        response = build_ajax_response(:error, nil, 'You already like that!')
        status = 401
      end
    else
      response = build_ajax_response(:error, nil, 'Target object not found!', nil)
      status = 404
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

  def destroy
    object = CoreObject.find(params[:id])
    if object
      if object.remove_from_likes(current_user)
        object.add_pop_action(:rp, :r, current_user)
        current_user.save if object.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.like_'+object.id.to_s, :toggle_classes => ['likeB', 'unlikeB']})
        status = 200
      else
        response = build_ajax_response(:error, nil, 'You have already unliked that!')
        status = 401
      end
    else
      response = build_ajax_response(:error, nil, 'Target object not found!', nil)
      status = 404
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end
end

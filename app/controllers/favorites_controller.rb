class FavoritesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @user = User.find_by_slug(params[:id])
    @title = @user.username + "'s favorites"
    unless @user
      not_found("User not found")
    end
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_favorites_path :p => page + 1
    @right_sidebar = true if current_user != @user

    @core_objects = CoreObject.feed(session[:feed_filters][:display], session[:feed_filters][:sort], {
            :includes_ids => @user.favorites,
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

  def create
    object = CoreObject.find(params[:id])
    if object
      if object.add_to_favorites(current_user)
        object.add_pop_action(:fav, :a, current_user) if object.user_id != current_user.id
        object.save
        current_user.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB']})
        status = 201
      else
        response = build_ajax_response(:error, nil, 'You have already favorited that!')
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
      if object.remove_from_favorites(current_user)
        object.add_pop_action(:fav, :r, current_user) if object.user_id != current_user.id
        current_user.save if object.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB']})
        status = 200
      else
        response = build_ajax_response(:error, nil, 'You have already unfavorited that!')
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

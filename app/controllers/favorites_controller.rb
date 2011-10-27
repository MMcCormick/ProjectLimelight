class FavoritesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @user = User.find_by_slug(params[:id])
    unless @user
      not_found("User not found")
    end
    page = params[:p] ? params[:p].to_i : 1
    @more_path = user_favorites_path :p => page + 1

    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
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
    if object && !object.favorited_by?(current_user.id)
      object.add_to_favorites(current_user)
      object.add_pop_action(:fav, :a, current_user)
      current_user.save if object.save
      pusher_publish(object.id.to_s, 'popularity_change', {:amount => :change_this, :popularity => object.pop_total})
      response = build_ajax_response(:ok, nil, nil, nil, {:id => object.id.to_s, :target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB'], :popularity => object.pop_total})
      status = 201
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
    if object && object.favorited_by?(current_user.id)
      object.remove_from_favorites(current_user)
      object.add_pop_action(:fav, :r, current_user)
      current_user.save if object.save
      pusher_publish(object.id.to_s, 'popularity_change', {:amount => :change_this, :popularity => object.pop_total})
      response = build_ajax_response(:ok, nil, nil, nil, {:id => object.id.to_s, :target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB'], :popularity => object.pop_total})
      status = 200
    else
      response = build_ajax_response(:error, nil, 'Target object not found!', nil)
      status = 404
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end
end

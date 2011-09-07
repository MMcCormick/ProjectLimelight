class FavoritesController < ApplicationController
  def index
    @user = User.find_by_slug(params[:id])
    @favorite_ids = []
    favs = CoreObject.where(:favorites => @user.id).only(:_id)
    favs.each do |fav|
      @favorite_ids << fav.id
    end

    @core_objects = CoreObject.feed(session[:feed_filters][:display], [:created_at, :desc], {
            :includes_ids => @favorite_ids
    })
  end

  def create
    object = CoreObject.find(params[:id])
    if object
      object.add_to_favorites(current_user)
      current_user.save if object.save
      response = {:status => 'ok', :target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB']}
    else
      response = {:status => 'error', :message => 'Target object not found!'}
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end

  def destroy
    object = CoreObject.find(params[:id])
    if object
      object.remove_from_favorites(current_user)
      current_user.save if object.save
      response = {:status => 'ok', :target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB']}
    else
      response = {:status => 'error', :message => 'Target object not found!'}
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end
end

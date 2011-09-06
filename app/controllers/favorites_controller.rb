class FavoritesController < ApplicationController
  def add
    object = CoreObject.find(params[:id])
    if object

      response = {:status => 'ok', :target => '.fav_'+object.id.to_s, :toggle_classes => ['favB', 'unfavB']}
    else
      response = {:status => 'error', :message => 'Target object not found!'}
    end
  end
end

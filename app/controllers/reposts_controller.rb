class RepostsController < ApplicationController
  def create
    object = CoreObject.find(params[:id])
    if object
      object.add_to_reposts(current_user)
      current_user.save if object.save
      response = {:status => 'ok', :target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB']}
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
      object.remove_from_reposts(current_user)
      current_user.save if object.save
      response = {:status => 'ok', :target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB']}
    else
      response = {:status => 'error', :message => 'Target object not found!'}
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end
end

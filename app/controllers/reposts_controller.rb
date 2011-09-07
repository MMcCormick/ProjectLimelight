class RepostsController < ApplicationController
  before_filter :authenticate_user!

  def create
    object = CoreObject.find(params[:id])
    if object
      object.add_to_reposts(current_user)
      current_user.save if object.save
      response = {:json => {:status => 'ok', :target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB']}, :status => 201}
    else
      response = {:json => {:status => 'error', :message => 'Target object not found!'}, :status => 404}
    end

    respond_to do |format|
      format.json { render response }
    end
  end

  def destroy
    object = CoreObject.find(params[:id])
    if object
      object.remove_from_reposts(current_user)
      current_user.save if object.save
      response = {:json => {:status => 'ok', :target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB']}, :status => 200}
    else
      response = {:json => {:status => 'error', :message => 'Target object not found!'}, :status => 404}
    end

    respond_to do |format|
      format.json { render response }
    end
  end
end

class FollowsController < ApplicationController

  def create
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if target
        current_user.follow_object(target)
        current_user.save
        target.save
        response = {:json => {:status => 'ok', :target => '.fol_'+target.id.to_s, :toggle_classes => ['followB', 'unfollowB']}, :status => 201}
      else
        response = {:json => {:status => 'error', :message => 'Target user not found!'}, :status => 404}
      end
    end

    respond_to do |format|
      format.json { render response }
    end
  end

  def destroy
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if target
        current_user.unfollow_object(target)
        current_user.save
        target.save
        response = {:json => {:status => 'ok', :target => '.fol_'+target.id.to_s, :toggle_classes => ['followB', 'unfollowB']}, :status => 201}
      else
        response = {:json => {:status => 'error', :message => 'Target user not found!'}, :status => 404}
      end
    end

    respond_to do |format|
      format.json { render response }
    end
  end

end
class FollowsController < ApplicationController
  before_filter :authenticate_user!

  def create
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if target
        current_user.follow_object(target)
        current_user.save
        target.add_pop_action(:flw, :a, current_user)
        target.save
        response = build_ajax_response(:ok, nil, nil, nil, { :target => '.fol_'+target.id.to_s, :toggle_classes => ['followB', 'unfollowB'], :popularity => target.pop_total})
        status = 201
      else
        response = build_ajax_response(:error, nil, 'Target not found!')
        status = 404
      end
    else
      response = build_ajax_response(:error, nil, 'Invalid object type')
      status = 400
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

  def destroy
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if target
        current_user.unfollow_object(target)
        current_user.save
        target.add_pop_action(:flw, :r, current_user)
        target.save
        response = build_ajax_response(:ok, nil, nil, nil, { :target => '.fol_'+target.id.to_s, :toggle_classes => ['followB', 'unfollowB'], :popularity => target.pop_total})
        status = 201
      else
        response = build_ajax_response(:error, nil, 'Target user not found!')
        status = 404
      end
    else
      response = build_ajax_response(:error, nil, 'Invalid object type')
      status = 400
    end

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

end
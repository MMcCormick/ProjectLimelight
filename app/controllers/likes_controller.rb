class LikesController < ApplicationController
  before_filter :authenticate_user!

  def create
    object = CoreObject.find(params[:id])
    if object
      if object.add_to_likes(current_user)
        object.add_pop_action(:rp, :a, current_user)
        current_user.save if object.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.like_'+object.id.to_s, :toggle_classes => ['likeB', 'unlikeB']})
        status = 201
      else
        response = build_ajax_response(:error, nil, 'You have already like that!')
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

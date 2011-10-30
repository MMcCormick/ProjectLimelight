class RepostsController < ApplicationController
  before_filter :authenticate_user!

  #TODO: don't allow users to repost their own
  def create
    object = CoreObject.find(params[:id])
    if object
      if object.add_to_reposts(current_user)
        pop_change = object.add_pop_action(:rp, :a, current_user)
        current_user.save if object.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB'],
                                                            :popularity => object.pop_total, :pop_change => pop_change})
        status = 201
      else
        response = build_ajax_response(:error, nil, 'You have already posted that!')
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
      if object.remove_from_reposts(current_user)
        pop_change = object.add_pop_action(:rp, :r, current_user)
        current_user.save if object.save
        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB'],
                                                            :popularity => object.pop_total, :pop_chagne => pop_change})
        status = 200
      else
        response = build_ajax_response(:error, nil, 'You have already undone that repost!')
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

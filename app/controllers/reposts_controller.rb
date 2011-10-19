class RepostsController < ApplicationController
  before_filter :authenticate_user!

  #TODO: don't allow users to repost their own
  def create
    object = CoreObject.find(params[:id])
    if object
      object.add_to_reposts(current_user)
      current_user.save if object.save
      response = build_ajax_response(:ok, nil, nil, nil, {:target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB']})
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
    if object
      object.remove_from_reposts(current_user)
      current_user.save if object.save
      response = build_ajax_response(:ok, nil, nil, nil, {:target => '.repost_'+object.id.to_s, :toggle_classes => ['repostB', 'unrepostB']})
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

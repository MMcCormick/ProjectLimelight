class FollowsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :json

  def create
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if current_user && target
        if current_user.follow_object(target)
          if params[:type] == 'User'
            @notification = Notification.add(target, :follow, true, current_user)
            if @notification
              Pusher["#{target.id.to_s}_private"].trigger('new_notification', render_to_string(:template => 'users/notification.json.rabl'))
            end
          end
          current_user.save
          response = build_ajax_response(:ok, nil, "You're following #{target.name}", nil, { })
          status = 201
        else
          response = build_ajax_response(:error, nil, "You're already following that!")
          status = 401
        end
      else
        response = build_ajax_response(:error, nil, 'Target not found!')
        status = 404
      end
    else
      response = build_ajax_response(:error, nil, 'Invalid object type')
      status = 400
    end

    render :json => response, :status => status
  end

  def destroy
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if current_user && target
        if current_user.unfollow_object(target)
          if params[:type] == 'User'
            Notification.remove(target, :follow, current_user)
          end

          target.save
          current_user.save

          response = build_ajax_response(:ok, nil, nil, nil, { })
          status = 201
         else
          response = build_ajax_response(:error, nil, "You're not following that!")
          status = 401
        end
      else
        response = build_ajax_response(:error, nil, 'Target user not found!')
        status = 404
      end
    else
      response = build_ajax_response(:error, nil, 'Invalid object type')
      status = 400
    end

    render :json => response, :status => status
  end

end
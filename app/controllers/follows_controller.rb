class FollowsController < ApplicationController
  before_filter :authenticate_user!
  include ModelUtilitiesHelper

  respond_to :json

  def create
    if ['User', 'Topic'].include? params[:type]
      target = Kernel.const_get(params[:type]).find(params[:id])
      if current_user && target
        if current_user.follow_object(target)
          if params[:type] == 'User'
            notification = Notification.add(target, :follow, true, current_user)
            if notification
              Pusher["#{target.id.to_s}_private"].trigger('new_notification', notification.to_json)
            end
          end

          if current_user.save
            track_mixpanel("Follow #{params[:type]}", current_user.mixpanel_data.merge(target.mixpanel_data(params[:type] == 'User' ? '2 ' : nil)))
          end

          # post to facebook open graph
          fb = current_user.facebook
          if fb
            if params[:type] == 'User'
              fb.put_connections("me", "#{og_namespace}:follow", :profile => user_url(target))
            else
              fb.put_connections("me", "#{og_namespace}:follow", :topic => '')
            end
          end

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

          if target.save && current_user.save
            track_mixpanel("Unfollow #{params[:type]}", current_user.mixpanel_data.merge(target.mixpanel_data(params[:type] == 'User' ? '2 ' : nil)))
          end

          # delete from facebook open graph
          fb = current_user.facebook
          if fb
            if params[:type] == 'User'
              fb.delete_connections("me", "#{og_namespace}:follow", :profile => user_url(target))
            else
              fb.delete_connections("me", "#{og_namespace}:follow", :topic => '')
            end
          end

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
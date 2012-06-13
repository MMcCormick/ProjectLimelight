class LikesController < ApplicationController
  before_filter :authenticate_user!

  def create
    object = Post.find(params[:id])
    if object
      like_success = object.add_to_likes(current_user)
      if like_success
        current_user.save if object.save

        track_mixpanel("Like Post", current_user.mixpanel_data.merge(object.mixpanel_data))

        # post to facebook open graph
        fb = current_user.facebook
        if fb
          unless object._type == 'Talk'
            object_url = post_url(:id => object.id)
            Resque.enqueue(OpenGraphCreate, current_user.id.to_s, object.id.to_s, object.class.name, 'like', 'post', object_url)
          end
        end

        # send the influence pusher notification
        if object.class.name == 'Talk'
          notification = Notification.add(object.user, :repost, true, current_user, nil, object, object.user)
          if notification
            Pusher["#{object.user.id.to_s}_private"].trigger('new_notification', notification.to_json)
          end
        end

        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.like_'+object.id.to_s, :toggle_classes => ['likeB', 'unlikeB']})
        status = 201
      elsif like_success.nil?
        response = build_ajax_response(:error, nil, 'You cannot like your own posts!')
        status = 401
      else
        response = build_ajax_response(:error, nil, 'You already liked that!')
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
    object = Post.find(params[:id])
    if object
      if object.remove_from_likes(current_user)
        current_user.save if object.save

        track_mixpanel("Unlike Post", current_user.mixpanel_data.merge(object.mixpanel_data))

        Notification.remove(object.user, :repost, current_user, object)

        Resque.enqueue(OpenGraphDelete, current_user.id.to_s, object.id.to_s, object.class.name, 'like')

        response = build_ajax_response(:ok, nil, nil, nil)
        status = 200
      else
        response = build_ajax_response(:error, nil, 'You have already unreposted that!')
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

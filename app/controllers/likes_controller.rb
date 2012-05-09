class LikesController < ApplicationController
  before_filter :authenticate_user!

  def create
    object = Post.find(params[:id])
    if object
      like_success = object.add_to_likes(current_user)
      if like_success
        current_user.save if object.save

        # send the influence pusher notification
        if object.class.name == 'Talk'

          notification = Notification.add(object.user, :repost, true, current_user, nil, object, object.user)
          if notification
            Pusher["#{object.user.id.to_s}_private"].trigger('new_notification', notification.to_json)
          end

          object.topic_mentions.each do |mention|
            increase = InfluenceIncrease.new
            increase.amount = like_success
            increase.topic_id = mention.id
            increase.object_type = 'Talk'
            increase.action = :lk
            increase.id = mention.name
            increase.topic = mention

            Pusher[object.user_id.to_s].trigger('influence_change', increase.to_json)
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
        Notification.remove(object.user, :repost, current_user, object)
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

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
          object.topic_mentions.each do |mention|
            @increase = InfluenceIncrease.new
            @increase.amount = like_success
            @increase.topic_id = mention.id
            @increase.object_type = 'Talk'
            @increase.action = :lk
            @increase.id = mention.name
            @increase.topic = mention

            Pusher[object.user_id.to_s].trigger('influence_change', render_to_string(:template => 'users/influence_increase.json.rabl'))
          end
        end

        response = build_ajax_response(:ok, nil, nil, nil, {:target => '.like_'+object.id.to_s, :toggle_classes => ['likeB', 'unlikeB']})
        status = 201
      elsif like_success.nil?
        response = build_ajax_response(:error, nil, 'You cannot like your own posts!')
        status = 401
      else
        response = build_ajax_response(:error, nil, 'You already like that!')
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

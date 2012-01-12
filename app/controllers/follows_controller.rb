class FollowsController < ApplicationController
  before_filter :authenticate_user!

  def create
    if ['User', 'UserSnippet', 'Topic', 'TopicSnippet'].include? params[:type]
      targets = {
              'User' => 'User',
              'UserSnippet' => 'User',
              'Topic' => 'Topic',
              'TopicSnippet' => 'Topic'
      }
      indexes = {
              'User' => 'users',
              'UserSnippet' => 'users',
              'Topic' => 'topics',
              'TopicSnippet' => 'topics'
      }
      target = Kernel.const_get(targets[params[:type]]).find(params[:id])
      if target && target.id
        if current_user.follow_object(target)
          if params[:type] == 'User'
            Notification.add(target, :follow, true, current_user)
          end
          current_user.save
          response = build_ajax_response(:ok, nil, nil, nil, { :target => '.fol_'+target.id.to_s, :toggle_classes => ['followB', 'unfollowB']})
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

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

  def destroy
    if ['User', 'UserSnippet', 'Topic', 'TopicSnippet'].include? params[:type]
      targets = {
              'User' => 'User',
              'UserSnippet' => 'User',
              'Topic' => 'Topic',
              'TopicSnippet' => 'Topic'
      }
      target = Kernel.const_get(targets[params[:type]]).find(params[:id])
      if target
        if current_user.unfollow_object(target)
          current_user.save
          if params[:type] == 'User'
            Notification.remove(target, :follow, current_user)
          end

          response = build_ajax_response(:ok, nil, nil, nil, { :target => '.fol_'+target.id.to_s, :toggle_classes => ['followB', 'unfollowB']})
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

    respond_to do |format|
      format.json { render :json => response, :status => status }
    end
  end

end
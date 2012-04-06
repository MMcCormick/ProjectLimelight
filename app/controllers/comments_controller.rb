class CommentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    talk = Talk.find(params[:talk_id])
    comment = talk.comments.new(params)
    comment.user_id = current_user.id

    if comment.save
      #comment.send_notifications(current_user)
      #comment.send_mention_notifications

      # Have to do this here because cannot render from outside controller...
      @notification = Notification.add(talk.user, :comment, true, current_user, nil, talk, talk.user, nil)
      Pusher["#{talk.user.id.to_s}_private"].trigger('new_notification', render_to_string(:template => 'users/notification.json.rabl'))
      siblings = Comment.where(:talk_id => talk.id)
      used_ids = []
      siblings.each do |sibling|
        unless used_ids.include?(sibling.user_id.to_s) || (talk.user_id == sibling.user_id) || (sibling.user_id == current_user.id)
          @notification = Notification.add(sibling.user, :also, true, current_user, nil, talk, talk.user, sibling)
          Pusher["#{sibling.user_id.to_s}_private"].trigger('new_notification', render_to_string(:template => 'users/notification.json.rabl'))
        end
        used_ids << sibling.user_id.to_s
      end

      response = build_ajax_response(:ok, nil, "Comment created!")
      render json: response, :status => 201
    else
      render json: build_ajax_response(:error, nil, "Comment could not be created", comment.errors), :status => 422
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    if comment
      authorize! :destroy, comment
      comment.user_delete
      if comment.save
        html = render_to_string :partial => "comments/comment", :locals => { :comment => comment }

        response = build_ajax_response(:ok, nil, "Comment successfully deleted", nil, { :id => comment.id, :comment => html })
        status = 200
      else
        response = build_ajax_response(:error, nil, "Comment could not be saved", comment.errors)
        status = 422
      end
    else
      response = build_ajax_response(:error, nil, "Comment could not be found")
      status = 404
    end
    render json: response, :status => status
  end
end
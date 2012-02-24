class CommentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    talk = Talk.find(params[:comment][:talk_id])
    comment = talk.comments.new(params[:comment])
    comment.user_id = current_user.id

    if comment.save
      comment.send_notifications(current_user)
      #comment.send_mention_notifications

      #talk.expire_caches BETA REMOVE
      html = render_to_string :partial => "comments/comment", :locals => { :comment => comment }
      response = build_ajax_response(:ok, nil, "Comment posted!", nil, { :parent_id => comment.parent_id, :talk_id => comment.talk_id, :comment => html })
      render json: response, :status => 201
    else
      render json: build_ajax_response(:error, nil, "Comment could not be posted", comment.errors), :status => 422
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
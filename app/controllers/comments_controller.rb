class CommentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    talk = Talk.find(params[:talk_id])
    comment = talk.comments.new(params)
    comment.user_id = current_user.id

    if comment.save
      comment.send_notifications(current_user)
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
class CommentsController < ApplicationController
  before_filter :authenticate_user!

  def create
    talk = Talk.find(params[:comment][:talk_id])
    comment = talk.comments.new(params[:comment].merge(:user => current_user))

    respond_to do |format|
      if comment.save
        html = render_to_string :partial => "comments/comment", :locals => { :comment => comment }
        response = build_ajax_response(:ok, nil, "Comment posted!", nil, { :parent_id => comment.parent_id, :comment => html })
        format.js { render json: response, :status => 201 }
      else
        format.js { render json: build_ajax_response(:error, nil, nil, comment.errors), :status => 422 }
      end
    end
  end
end
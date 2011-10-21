class CommentCell < Cell::Rails

  include Devise::Controllers::Helpers
  helper UsersHelper
  helper ApplicationHelper
  helper TopicsHelper

  def thread(talk_id, with_forms=false)
    @talk_id = talk_id
    @with_forms = with_forms
    @comments = Comment.threaded_with_field(talk_id)
    @user = current_user

    render
  end

end

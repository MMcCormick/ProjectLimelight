#class CommentCell < Cell::Rails
#
#  include Devise::Controllers::Helpers
#  include CanCan::ControllerAdditions
#  helper UsersHelper
#  helper ApplicationHelper
#  helper TopicsHelper
#
#  def thread(talk_id, with_forms=false, limit=nil)
#    @talk_id = talk_id
#    @with_forms = with_forms
#    @comments = Comment.threaded_with_field(talk_id, 'created_at', limit)
#    @user = current_user
#    @limit = limit
#
#    render
#  end
#
#end
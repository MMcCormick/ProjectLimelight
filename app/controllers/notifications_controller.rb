class NotificationsController < ApplicationController
  before_filter :authenticate_user!, :is_users_page?

  def index
      @notifications = Notification.where('receiver_snippets._id' => current_user.id)
      current_user.unread_notification_count = 0
      current_user.save

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @core_core_object_share }
      end
  end
end
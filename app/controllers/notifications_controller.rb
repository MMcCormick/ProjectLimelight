class NotificationsController < ApplicationController
  before_filter :authenticate_user!, :is_users_page?

  def index
      @notifications = Notification.where('user_id' => current_user.id).order_by(:updated_at, 'DESC')
      if current_user.unread_notification_count > 0
        Notification.where('user_id' => current_user.id).update_all({'read' => true})
        current_user.unread_notification_count = 0
        current_user.save
      end
  end
end
class NotificationsController < ApplicationController
  before_filter :authenticate_user!, :is_users_page?

  def index
    @site_style = 'narrow'
    @title = "Notifications"
    @notifications = Notification.where('user_id' => current_user.id, :updated_at.gt => Chronic.parse('one month ago')).order_by(:updated_at, 'DESC').to_a
    if current_user.unread_notification_count > 0
      Notification.where('user_id' => current_user.id).update_all({'read' => true})
      current_user.unread_notification_count = 0
      current_user.save
    end
  end
end
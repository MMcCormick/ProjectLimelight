class SendUserNotification
  include Resque::Plugins::UniqueJob

  @queue = :slow_limelight

  def self.perform(notification_id)
    notification = Notification.find(notification_id)

    if notification && !notification.read && !notification.emailed
      user = User.find(notification.user_id)
      NotificationMailer.immediate_notification(user, notification).deliver
      # Set notification to emailed
      notification.emailed = true
      notification.save
    end
  end
end
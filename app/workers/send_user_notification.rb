class SendUserNotification
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform(notification_id)
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
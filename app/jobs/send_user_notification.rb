class SendUserNotification
  include Resque::Plugins::UniqueJob

  @queue = :slow

  def self.perform(notification_id)
    notification = Notification.find(notification_id)

    if notification
      user = User.find(notification.user_id)
      NotificationMailer.immediate_notification(user, notification).deliver
      # Set each notification to emailed
      notifications.each do |notification|
        notification.set_emailed
        notification.save
      end
    end
  end
end
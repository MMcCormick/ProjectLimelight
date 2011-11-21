class SendUserNotification
  @queue = :notifications

  def self.perform
    users = User.all
    users.each do |user|
      if user.notify_email
        notifications = Notification.where(
                :user_id => user.id,
                :active => true,
                :read => false,
                :notify => true,
                :emailed => false)

        if notifications && notifications.length > 0
          NotificationMailer.new_notifications(user, notifications).deliver
          # Set each notification to emailed
          notifications.each do |notification|
            notification.set_emailed
            notification.save
          end
        end
      end
    end
  end
end
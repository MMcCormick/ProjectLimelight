class SendDailyUserNotifications
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform
    users = User.all
    users.each do |user|
      notifications = Notification.where(
              :user_id => user.id,
              :active => true,
              :read => false,
              :notify => true,
              :emailed => false,
              :type => {"$in" => user.daily_notification_types})

      if notifications && notifications.length > 0
        NotificationMailer.new_notifications(user, notifications).deliver
        # Set each notification to emailed
        notifications.each do |notification|
          notification.emailed = true
          notification.save
        end
      end
    end
  end

end
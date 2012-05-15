class NotificationMailer < ActionMailer::Base
  helper NotificationsHelper
  helper UsersHelper
  helper CoreObjectsHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def new_notifications(user, notifications)
    @user = user
    @notifications = notifications
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.first_or_username}, you've got new notifications")
  end

  def immediate_notification(user, notification)
    @user = user
    @notification = notification
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => @notification.triggered_by.first_or_username + @notification.notification_text)
  end
end
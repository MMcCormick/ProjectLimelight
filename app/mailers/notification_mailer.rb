class NotificationMailer < ActionMailer::Base
  helper NotificationsHelper
  helper UsersHelper
  helper CoreObjectsHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def new_notifications(user, notifications)
    @user = user
    @notifications = notifications
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.username}, you've got new notifications")
  end
end
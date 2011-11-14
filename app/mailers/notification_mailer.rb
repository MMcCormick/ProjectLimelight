class NotificationMailer < ActionMailer::Base
  helper NotificationsHelper
  helper UsersHelper
  helper CoreObjectsHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def new_notifications(user, notifications)
    @user = user
    @notifications = notifications
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "You've got new notifications on Limelight")
  end
end
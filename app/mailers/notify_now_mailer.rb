class NotifyNowMailer < ActionMailer::Base
  helper UsersHelper
  helper CoreObjectsHelper
  helper NotificationsHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def notify(from, to, notification)
    @to_user = to
    @notification = notification
    subject = case notification.type.to_sym
      when :share then "#{from.first_or_username} shared a post with you on Limelight"
      when :mention then "#{from.first_or_username} mentioned you in a post on Limelight"
      when :follow then "#{from.first_or_username} is following you on Limelight"
      when :reply then "#{from.first_or_username} replied to you on Limelight"
      when :also then "#{from.first_or_username} also commented on a Limelight post"
    end

    mail(:to => "#{to.fullname} <#{to.email}>", :subject => subject)
  end
end
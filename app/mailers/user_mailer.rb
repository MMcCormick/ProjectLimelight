class UserMailer < ActionMailer::Base
  helper UsersHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def welcome_email(user)
    @user = user
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.username}, welcome to Limelight")
  end

  def invite_email(user, email)
    @user = user
    mail(:to => "#{email}", :subject => "#{user.username} invites you to join Limelight")
  end
end
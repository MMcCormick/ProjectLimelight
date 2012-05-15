class UserMailer < ActionMailer::Base
  include Resque::Mailer
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def welcome_email(user)
    @user = user
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.first_name && !user.first_name.blank? ? user.first_name : user.username}, welcome to Limelight")
  end

  def invite_email(user, email)
    @user = user
    mail(:to => "#{email}", :subject => "#{user.fullname ? user.fullname : user.username} invites you to join Limelight")
  end

  def beta_signup_email(email)
    @email = email
    mail(:to => "#{email}", :subject => "Thanks for signing up for the Limelight Beta!")
  end
end
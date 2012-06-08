class UserMailer < ActionMailer::Base
  include Resque::Mailer
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email', :except => [:matt_welcome, :marc_welcome]

  def welcome_email(user_id)
    @user = User.find(user_id)
    mail(:to => "#{@user.fullname} <#{@user.email}>", :subject => "#{@user.first_name && !@user.first_name.blank? ? @user.first_name : @user.username}, welcome to Limelight")
  end

  def welcome_email_admins(user_id)
    user = User.find(user_id)
    mail(:to => 'support@projectlimelight.com', :reply_to => user.email, :subject => "[limelight signup] #{user.fullname ? user.fullname + '(' + user.username + ')' : user.username} signed up!")
  end

  def beta_signup_email(email)
    mail(:to => email, :subject => "Thanks for signing up for the Limelight Beta!")
  end

  def beta_signup_email_admins(email)
    mail(:to => 'support@projectlimelight.com', :subject => "[limelight invite request] #{email} requested an invite!")
  end

  def matt_welcome(user_id)
    @user = User.find(user_id)
    mail(:from => "matt@projectlimelight.com", :to => "#{@user.fullname} <#{@user.email}>", :subject => "Thanks")
  end

  def marc_welcome(user_id, today_or_yesterday)
    @user = User.find(user_id)
    @today_or_yesterday = today_or_yesterday
    mail(:from => "marc@projectlimelight.com", :to => "#{@user.fullname} <#{@user.email}>", :subject => "Hi There")
  end
end
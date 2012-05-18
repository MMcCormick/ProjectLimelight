class UserMailer < ActionMailer::Base
  include Resque::Mailer
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email', :except => [:matt_welcome, :marc_welcome]

  def welcome_email(user_id)
    @user = User.find(user_id)
    mail(:to => "#{@user.fullname} <#{@user.email}>", :subject => "#{@user.first_name && !@user.first_name.blank? ? @user.first_name : @user.username}, welcome to Limelight")
  end

  def beta_signup_email(email)
    mail(:to => email, :subject => "Thanks for signing up for the Limelight Beta!")
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

  # Depricated
  #def invite_email(user_id, email)
  #  @user = User.find(user_id)
  #  mail(:to => email, :subject => "#{@user.fullname ? @user.fullname : @user.username} invites you to join Limelight")
  #end
end
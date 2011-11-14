class ShareMailer < ActionMailer::Base
  helper UsersHelper
  helper CoreObjectsHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def share(from, to, object, object_user)
    @from_user = from
    @to_user = to
    @shared = object
    @object_user = object_user
    mail(:to => "#{to.fullname} <#{to.email}>", :subject => "#{from.username} shared a post with you")
  end
end
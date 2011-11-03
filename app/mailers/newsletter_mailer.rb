class NewsletterMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  add_template_helper(ImageHelper)

  default :from => "support@projectlimelight.com"
  layout 'email'

  def weekly_email(user)
    @user = user
    @pictures = CoreObject.feed(['Picture'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    @talks = CoreObject.feed(['Talk'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    @videos = CoreObject.feed(['Video'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    @news = CoreObject.feed(['News'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.username}, here are your weekly recommendations from Limelight")
  end
end
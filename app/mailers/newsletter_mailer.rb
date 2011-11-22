class NewsletterMailer < ActionMailer::Base
  helper ApplicationHelper
  helper ImageHelper
  helper UsersHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email'

  def weekly_email(user, pop_talks, pop_news, pop_pics, pop_vids)
    @user = user
    talks = CoreObject.feed(['Talk'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    news = CoreObject.feed(['News'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    pictures = CoreObject.feed(['Picture'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })
    videos = CoreObject.feed(['Video'], {:target=>:pw, :order=>"desc"}, {
            :created_by_users => @user.following_users,
            :reposted_by_users => @user.following_users,
            :mentions_topics => @user.following_topics,
            :mentions_users => [@user.id],
            :limit => 3
    })

    @talks = talks.length > 0 ? talks : pop_talks
    @news = news.length > 0 ? news : pop_news
    @pictures = pictures.length > 0 ? pictures : pop_pics
    @videos = videos.length > 0 ? videos : pop_vids

    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.first_or_username}, here are your weekly recommendations from Limelight")
  end
end
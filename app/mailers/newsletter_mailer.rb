class NewsletterMailer < ActionMailer::Base
  helper ApplicationHelper
  helper ImageHelper
  default :from => "Limelight <support@projectlimelight.com>"
  layout 'email_no_logo'

  def weekly_email(user, pop_talks, pop_links, pop_pics, pop_vids)
    interests = Neo4j.user_interests(user.id, 20)
    interests = interests[:specific].map{ |i| BSON::ObjectId(i[:data]['id']) }

    talks = FeedTopicItem.where(:mentions.in => interests, :root_type => 'Talk').desc(:p).limit(3).to_a
    links = FeedTopicItem.where(:mentions.in => interests, :root_type => 'Link').desc(:p).limit(3).to_a
    pictures = FeedTopicItem.where(:mentions.in => interests, :root_type => 'Picture').desc(:p).limit(3).to_a
    videos = FeedTopicItem.where(:mentions.in => interests, :root_type => 'Video').desc(:p).limit(3).to_a

    obj_ids = []
    [talks, links, pictures, videos].each do |objs|
      obj_ids = obj_ids + objs.map{ |obj| obj.root_id }
    end
    objects = Post.where(:_id.in => obj_ids)

    talks = objects.select{|o| o._type == 'Talk'}
    links = objects.select{|o| o._type == 'Link'}
    pictures = objects.select{|o| o._type == 'Picture'}
    videos = objects.select{|o| o._type == 'Video'}

    @talks = talks.length > 0 ? talks : pop_talks
    @links = links.length > 0 ? links : pop_links
    @pictures = pictures.length > 0 ? pictures : pop_pics
    @videos = videos.length > 0 ? videos : pop_vids
    @user = user

    mail(:to => "#{user.fullname} <#{user.email}>", :subject => "#{user.first_or_username}, here are your weekly recommendations from Limelight")
  end
end
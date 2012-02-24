class TestingController < ApplicationController

  def test
    talks = FeedTopicItem.where(:root_type => 'Talk').order_by([[:p, :desc]]).limit(3).to_a
    links = FeedTopicItem.where(:root_type => 'Link').order_by([[:p, :desc]]).limit(3).to_a
    pictures = FeedTopicItem.where(:root_type => 'Picture').order_by([[:p, :desc]]).limit(3).to_a
    videos = FeedTopicItem.where(:root_type => 'Video').order_by([[:p, :desc]]).limit(3).to_a

    obj_ids = []
    [talks, links, pictures, videos].each do |objs|
      obj_ids = obj_ids + objs.map{ |obj| obj.root_id }
    end
    objects = Post.where(:_id.in => obj_ids)

    pop_talks = objects.select{|o| o._type == 'Talk'}
    pop_links = objects.select{|o| o._type == 'Link'}
    pop_pics = objects.select{|o| o._type == 'Picture'}
    pop_vids = objects.select{|o| o._type == 'Video'}

    NewsletterMailer.weekly_email(current_user, pop_talks, pop_links, pop_pics, pop_vids).deliver if current_user.weekly_email
  end

  def foo
    user = current_user
    if !user.notify_email
      notifications = Notification.where(
          :user_id => user.id,
          :active => true,
          :read => false,
          :notify => true,
          :emailed => false,
          :type => {"$in" => user.notification_types})

      if notifications && notifications.length > 0
        NotificationMailer.new_notifications(user, notifications).deliver
        # Set each notification to emailed
        notifications.each do |notification|
          notification.set_emailed
          notification.save
        end
      end
    end
  end

end
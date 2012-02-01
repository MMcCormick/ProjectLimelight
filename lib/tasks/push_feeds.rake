namespace :push_feeds do

  desc "Create initial push feeds from the old architecture"
  task :migrate => :environment do
    # get all objects
    CoreObject.all.each do |co|

      # do we need to split a link into a talk?
      if co._type != 'Talk' && !co.content.blank?
        Talk.create(
          :content => co.content,
          :content_raw => co.content,
          :user_id => co.user_id,
          :parent => co
        )
        co.content = ''
      end

      co.set_root
      co.save
    end

    # Reset clout
    User.all.each do |u|
      u.clout = 1
      u.save
    end

    # Create likes from pop actions
    used_ids = []
    PopularityAction.all.each do |pa|
      next if used_ids.include?(pa.object_id.to_s) || pa.type == 'flw'

      used_ids << pa.object_id.to_s
      object = CoreObject.find(pa.object_id)
      user = User.find(pa.user_id)
      if object && user
        object.add_to_likes(user)
        object.save
        user.save
      end
    end

    # Remove old pop actions
    PopularityAction.delete_all(:conditions => {:t => {'$ne' => 'lk'}})

    # Refollow all users/topics for each user
    User.all.each do |u|
      u.following_users.each do |f|
        fol = User.find(f)
        fol.add_pop_action(:flw, :a, u)
        fol.save
      end

      u.following_topics.each do |f|
        fol = Topic.find(f)
        fol.add_pop_action(:flw, :a, u)
        fol.save
      end
      u.save
    end

    # loop through all core objects and push to feeds
    CoreObject.all.each do |co|

      # set the primary topic mention
      mentions = Topic.where(:_id => {'$in' => co.topic_mentions.map{|t| t.id}})
      mentions.each do |topic|
        if !co.primary_topic_pm || topic.pt > co.primary_topic_pm
          co.primary_topic_mention = topic.id
          co.primary_topic_pm = topic.pm
        end
      end
      co.save

      FeedUserItem.post_create(co)
      FeedTopicItem.post_create(co) unless co.class.name == 'Talk' || co.topic_mentions.empty?
      FeedContributeItem.create(co)
    end
  end

end
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
    objects = CoreObject.where(:_id.in => obj_ids)

    pop_talks = objects.select{|o| o._type == 'Talk'}
    pop_links = objects.select{|o| o._type == 'Link'}
    pop_pics = objects.select{|o| o._type == 'Picture'}
    pop_vids = objects.select{|o| o._type == 'Video'}

    NewsletterMailer.weekly_email(current_user, pop_talks, pop_links, pop_pics, pop_vids).deliver if current_user.weekly_email
  end

  def foobar
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

      # Set the primary topic mention
      if co.topic_mentions && co.topic_mentions.length > 0
        topics = Topic.where(:_id => {'$in' => co.topic_mentions.map{|m| m.id}})
        primary_mention_score = -9999
        primary_topic_mention = nil
        topics.each do |t|
          if t.score > primary_mention_score
            primary_mention_score = t.score
            primary_topic_mention = t.id
          end
        end

        co.primary_topic_mention = primary_topic_mention if primary_topic_mention
      end

      co.set_root
      co.save!
    end

    # Reset clout
    User.all.each do |u|
      u.clout = 1
      u.save
    end

    # Create likes from pop actions
    used_ids = []
    PopularityAction.all.each do |pa|
      found = used_ids.detect{|d| d[:post_id] == pa.object_id.to_s && d[:user_id] == pa.user_id.to_s}
      next if pa.type == 'flw' || pa.type == 'new' || pa.type == 'v_down' || found

      used_ids << {
              :post_id => pa.object_id.to_s,
              :user_id => pa.user_id.to_s
      }
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

    # loop through all core objects and push to feeds + some other things
    CoreObject.all.each do |co|

      # set the primary topic mention
      mentions = Topic.where(:_id => {'$in' => co.topic_mentions.map{|t| t.id}})
      mentions.each do |topic|
        if !co.primary_topic_pm || topic.pt > co.primary_topic_pm
          co.primary_topic_mention = topic.id
          co.primary_topic_pm = topic.pm
        end
      end

      # update the response count
      if ['Video', 'Picture', 'Link'].include?(co.class.name)
        responses = Talk.where(:root_id => co.id).to_a
        if responses
          co.response_count = responses.length
        else
          co.response_count = 0
        end
      end

      co.save!

      FeedUserItem.post_create(co)
      FeedTopicItem.post_create(co) unless co.response_to || co.topic_mentions.empty?
      FeedContributeItem.create(co)

    end

  end

  def foo
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

    # loop through all core objects and push to feeds
    CoreObject.all.each do |co|
      # set the primary topic mention
      mentions = Topic.where(:_id => {'$in' => co.topic_mentions.map{|t| t.id}}).to_a
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
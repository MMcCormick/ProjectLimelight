class FeedItem
  include Mongoid::Document

  field :feed_id, :type => BSON::ObjectId
  field :feed_type
  field :root_id
  field :root_type
  field :strength
  field :responses, :type => Array
  field :last_response_time, :type => DateTime

  class << self
    def post_create(post, popular_talk=false)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}
      user_mention_ids = post.user_mentions.map{|um| um.id}

      if post.class.name != 'Talk'
        user_feed_users = User.only(:id, :following_topics, :following_users).any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_snippet.id}, {:following_topics => {'$in' => topic_mention_ids}})
      elsif popular_talk
        user_feed_users = User.only(:id, :following_topics, :following_users).where(:following_topics => {'$in' => topic_mention_ids})
      else
        user_feed_users = User.only(:id, :following_topics, :following_users).any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_snippet.id})
      end

      updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      updates["$addToSet"] = { :responses => post.id } unless post.is_root?

      user_feed_users.each do |u|
        strength = 0
        if popular_talk
          strength += (topic_mention_ids & u.following_topics).length
        else
          strength += (topic_mention_ids & u.following_topics).length unless post.class.name == 'Talk'
          strength += 1 if u.following_users.include?(post.user_snippet.id)
          strength += 1 if user_mention_ids.include?(u.id)
        end
        updates["$inc"] = { :strength => strength }

        FeedItem.collection.update({:feed_id => u.id, :feed_type => 'uf', :root_id => post.root_id}, updates, {:upsert => true})
      end
    end


    #TODO: incorporate an .only like above?
    def follow(user, target)
      if target.class.name == 'Topic'
        core_objects = CoreObject.where('topic_mentions._id' => target.id)
      else
        core_objects = CoreObject.where('user_snippet._id' => target.id)
      end
      core_objects.each do |post|
        unless target.class.name == 'Topic' && post.class.name == 'Talk' && !post.is_popular

          updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
          updates["$addToSet"] = { :responses => post.id } unless post.is_root?
          updates["$inc"] = { :strength => 1 }

          FeedItem.collection.update({:feed_id => user.id, :feed_type => 'uf', :root_id => post.root_id }, updates, {:upsert => true})
        end
      end
    end

    def unfollow(user, target)
      if target.class.name == 'Topic'
        core_objects = CoreObject.where('topic_mentions._id' => target.id)
      else
        core_objects = CoreObject.where('user_snippet._id' => target.id)
      end
      core_objects.each do |post|
        unless target.class.name == 'Topic' && post.class.name == 'Talk' && !post.is_popular

          keep = false
          unless post.is_root?
            keep = true if post.topic_mentions.detect{ |t| t.id != target.id && user.is_following_topic?(t.id) }
            keep = true if target.class.name == 'Topic' && user.is_following_user?(post.user_snippet.id)
            keep = true if post.user_mentions.detect{ |u| u.id == user.id }
          end

          updates = {"$inc" => { :strength => -1 }}
          updates["$pull"] = { :responses => post.id } unless post.is_root? || keep

          FeedItem.collection.update({:feed_id => user.id, :feed_type => 'uf', :root_id => post.root_id }, updates)
        end
      end
      FeedItem.delete_all(conditions: { :feed_id => user.id, :feed_type => 'uf', :strength => {"$lte" => 0} })
    end
  end
end
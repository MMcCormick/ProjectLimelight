class FeedUserItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :feed_id, :type => BSON::ObjectId
  field :root_id
  field :root_type
  field :strength
  field :responses, :type => Array
  field :last_response_time, :type => DateTime

  class << self
    def post_create(post, popular_talk=false)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}
      user_mention_ids = post.user_mentions.map{|um| um.id}
      
      user_feed_users = User.only(:id, :following_topics, :following_users)

      if post.class.name != 'Talk'
        user_feed_users = user_feed_users.any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_snippet.id}, {:following_topics => {'$in' => topic_mention_ids}})
      elsif popular_talk
        user_feed_users = user_feed_users.where(:following_topics => {'$in' => topic_mention_ids})
      else
        user_feed_users = user_feed_users.any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_snippet.id})
      end

      updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      updates["$addToSet"] = { :responses => post.id } unless post.is_root?

      user_feed_users.each do |u|
        unless u.id == post.user_snippet.id
          strength = 0
          if popular_talk
            strength += (topic_mention_ids & u.following_topics).length
          else
            strength += (topic_mention_ids & u.following_topics).length unless post.class.name == 'Talk'
            strength += 1 if u.following_users.include?(post.user_snippet.id)
            strength += 1 if user_mention_ids.include?(u.id)
          end
          updates["$inc"] = { :strength => strength }

          FeedUserItem.collection.update({:feed_id => u.id, :root_id => post.root_id}, updates, {:upsert => true})
        end
      end
    end

    def post_disable(post, unpopular_talk=false)
      if post.is_root?
        FeedUserItem.destroy_all(conditions: { :root_id => post.id })
      else
        feed_items = FeedUserItem.where(:responses => post.id)
        foobar = feed_items.map{ |f| f.feed_id }
        user_feed_users = User.only(:id, :following_topics, :following_users).where(:_id => { '$in' => foobar })

        user_feed_users.each do |u|
          unless u.id == post.user_snippet.id
            strength = 0
            strength -= (post.topic_mentions.map{|tm| tm.id} & u.following_topics).length unless unpopular_talk
            strength -= 1 if u.is_following_user?(post.user_snippet.id)
            strength -= 1 if post.user_mentions.detect{ |us| us.id == user.id }
            strength -= 1 if post.likes.detect{ |l| u.is_following_user?(l.id) }

            updates = {"$inc" => { :strength => strength }}
            updates["$pull"] = { :responses => post.id }

            FeedUserItem.collection.update({:feed_id => u.id, :root_id => post.root_id}, updates, {:upsert => true})
          end
        end
        FeedUserItem.destroy_all(conditions: { :strength => {"$lte" => 0} })
      end
    end

    #TODO: incorporate an .only like above?
    def follow(user, target)
      if target.class.name == 'Topic'
        core_objects = CoreObject.where('topic_mentions._id' => target.id)
      else
        core_objects = CoreObject.any_of({'user_snippet._id' => target.id}, {'likes._id' => target.id})
      end
      core_objects.each do |post|
        unless user.id == post.user_snippet.id
          unless target.class.name == 'Topic' && post.class.name == 'Talk' && !post.is_popular

            updates = {"$set" => { :root_type => post.root_type, :last_response_time => post.created_at }}
            updates["$addToSet"] = { :responses => post.id } unless post.is_root?
            updates["$inc"] = { :strength => 1 }

            FeedUserItem.collection.update({:feed_id => user.id, :root_id => post.root_id }, updates, {:upsert => true})
          end
        end
      end
    end

    def unfollow(user, target)
      if target.class.name == 'Topic'
        core_objects = CoreObject.where('topic_mentions._id' => target.id)
      else
        core_objects = CoreObject.any_of('user_snippet._id' => target.id, 'likes._id' => target.id)
      end
      core_objects.each do |post|
        unless user.id == post.user_snippet.id
          unless target.class.name == 'Topic' && post.class.name == 'Talk' && !post.is_popular
            keep = false
            unless post.is_root?
              keep = true if target.class.name == 'Topic' && user.is_following_user?(post.user_snippet.id) ||
                             post.user_mentions.detect{ |u| u.id == user.id } ||
                             post.topic_mentions.detect{ |t| t.id != target.id && user.is_following_topic?(t.id) } ||
                             post.likes.detect{ |l| l.id != target.id && user.is_following_user?(l.id) }
            end

            updates = {"$inc" => { :strength => -1 }}
            updates["$pull"] = { :responses => post.id } unless post.is_root? || keep

            FeedUserItem.collection.update({:feed_id => user.id, :root_id => post.root_id }, updates)
          end
        end
      end
      FeedUserItem.destroy_all(conditions: { :feed_id => user.id, :strength => {"$lte" => 0} })
    end

    def like(user, post)
      user_feed_users = User.only(:id).where(:following_users => user.id)

      updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      updates["$addToSet"] = { :responses => post.id } unless post.is_root?
      updates["$inc"] = { :strength => 1 }
      updates["$set"]["likes.#{user.id.to_s}_#{post.id.to_s}"] = {
              :clout => user.clout,
              :created_at => Time.now
      }

      user_feed_users.each do |u|
        unless u.id == post.user_snippet.id
          FeedUserItem.collection.update({:feed_id => u.id, :root_id => post.root_id}, updates, {:upsert => true})
        end
      end
    end

    def unlike(user, post)
      user_feed_users = User.only(:id, :following_topics, :following_users).where(:following_users => user.id)

      updates = {"$inc" => { :strength => -1 }, "$unset" => {"likes.#{user.id.to_s}_#{post.id.to_s}" => 1}}

      user_feed_users.each do |follower|
        unless follower.id == post.user_snippet.id
          keep = false
          unless post.is_root?
            keep = true if follower.is_following_user?(post.user_snippet.id) ||
                           post.user_mentions.detect{ |u| u.id == follower.id } ||
                           post.topic_mentions.detect{ |t| follower.is_following_topic?(t.id) } ||
                           post.likes.detect{ |l| u.is_following_user?(l.id) }
          end

          updates["$pull"] = { :responses => post.id } unless post.is_root? || keep

          FeedUserItem.collection.update({:feed_id => follower.id, :root_id => post.root_id }, updates)
        end
      end
      FeedUserItem.destroy_all(conditions: { :strength => {"$lte" => 0} })
    end
  end
end
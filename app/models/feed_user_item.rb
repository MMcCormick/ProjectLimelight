class FeedUserItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :feed_id, :type => BSON::ObjectId
  field :root_id
  field :root_type
  field :ds, :default => 0
  field :dt, :default => Time.now
  field :responses, :default => [], :type => Array
  field :last_response_time, :type => DateTime
  field :p, :default => 0
  field :rel, :default => 0
  field :reasons, :default => []

  index [[ :root_id, Mongo::DESCENDING ]]
  index :responses
  index(
    [
      [ :feed_id, Mongo::DESCENDING ],
      [ :root_id, Mongo::DESCENDING ],
      [ :rel, Mongo::DESCENDING ]
    ]
  )
  index(
    [
      [ :feed_id, Mongo::DESCENDING ],
      [ :root_type, Mongo::DESCENDING ],
      [ :rel, Mongo::DESCENDING ]
    ]
  )
  index(
    [
      [ :feed_id, Mongo::DESCENDING ],
      [ :root_type, Mongo::DESCENDING ],
      [ :last_response_time, Mongo::DESCENDING ]
    ]
  )

  def add_reason(type, target, target2=nil)
    self.reasons ||= []
    self.ds ||= 0
    unless reasons.detect{|r| r['t'] == type && r['id'] == target.id.to_s}
      reason = {
              't' => type,
              'n' => target.name ? target.name : target.username,
              'id' => target.id.to_s
      }

      if target2
        reason['n2'] = target2.name
        reason['id2'] = target2.id.to_s
      end

      self.reasons << reason
      self.ds += 1
    end
  end

  def remove_reason(type, target)
    self.reasons.delete_if{|r| r['t'] == type && r['id'] == target.id.to_s}
    self.ds -= 1
  end

  class << self

    # foo
    def push_post_through_users(post)
      user_mention_ids = post.user_mentions.map{|um| um.id}

      # make the root post
      root_post = RootPost.new
      if post.is_root?
        root_post.root = post
      else
        root_post.root = post.root
      end

      root_post.public_talking = root_post.root.response_count

      # the potential users this post can be pushed to
      # take care of user mentions and users that are following the user that posted this
      user_feed_users = User.only(:id, :following_topics, :following_users).any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_snippet.id})

      # do not consider users this post has already been pushed to
      user_feed_users = user_feed_users.where(:_id => {"$nin" => post.pushed_users}) if post.pushed_users.length > 0

      # push to these users
      user_feed_users.each do |u|
        item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

        new_push = false

        unless item
          new_push = true
          post.pushed_users << u.id.to_s
          post.pushed_users_count += 1
          item = FeedUserItem.new(:feed_id => u.id, :root_id => post.root_id)
        end

        item.root_type = post.root_type
        item.last_response_time = Time.now
        item.responses ||= []
        item.responses << post.id unless post.is_root?

        # add following user reason
        item.add_reason('fu', post.user_snippet) if u.following_users.include?(post.user_snippet.id)

        # add mentioned reason
        item.add_reason('m', post.user_snippet) if user_mention_ids.include?(u.id)

        item.save if item.reasons.length > 0

        # if it's a new feed post, push it to the users feed
        Pusher["#{u.id.to_s}_realtime"].trigger('new_post', root_post.to_json(:user => u)) if new_push
      end

      post.save
    end

    def push_post_through_topics(post)

      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}

      topics = Topic.where(:_id => {"$in" => topic_mention_ids})
      topic_neo4j_ids = topics.map{|t| t.neo4j_id}
      neo4j_topic_ids = Neo4j.pulled_from_ids(topic_neo4j_ids)
      topics = Topic.where(:_id => {"$in" => topic_mention_ids + neo4j_topic_ids.map{|t| t[1]}})

      # make the root post
      root_post = RootPost.new
      if post.is_root?
        root_post.root = post
      else
        root_post.root = post.root
      end

      root_post.public_talking = root_post.root.response_count

      # push through topics
      unless post.class.name == 'Talk'
        topics.each do |topic|

          # the potential users this post can be pushed to
          user_feed_users = User.only(:id, :following_topics).where(:following_topics => topic.id)

          user_feed_users.each do |u|
            item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

            new_push = false

            unless item
              new_push = true
              post.pushed_users << u.id.to_s
              post.pushed_users_count += 1
              item = FeedUserItem.new(:feed_id => u.id, :root_id => post.root_id)
            end

            item.root_type = post.root_type
            item.last_response_time = Time.now
            item.responses ||= []
            item.responses << post.id unless post.is_root?

            # add following topic reason
            if topic_mention_ids.include?(topic.id) && u.following_topics && u.following_topics.include?(topic.id)
              item.add_reason('ft', topic)
            else # following topic related to another topic you're following
              original_topic = neo4j_topic_ids.detect{|tid| tid[1].to_s == topic.id.to_s}
              if original_topic
                original_topic = topics.detect{|t| original_topic[0] == t.id}
                item.add_reason('frt', topic, original_topic) if original_topic
              end
            end

            item.save if item.reasons.length > 0

            # if it's a new feed post, push it to the users feed
            Pusher["#{u.id.to_s}_realtime"].trigger('new_post', root_post.to_json(:user => u)) if new_push
          end
        end
      end

      post.save

    end

    def post_disable(post, unpopular_talk=false)
      #if post.is_root?
      #  FeedUserItem.destroy_all(conditions: { :root_id => post.id })
      #else
      #  feed_items = FeedUserItem.where(:responses => post.id)
      #  foobar = feed_items.map{ |f| f.feed_id }
      #  user_feed_users = User.only(:id, :following_topics, :following_users).where(:_id => { '$in' => foobar })
      #
      #  user_feed_users.each do |u|
      #    unless u.id == post.user_snippet.id
      #      strength = 0
      #      strength -= 1 if u.is_following_user?(post.user_snippet.id)
      #      strength -= 1 if post.user_mentions.detect{ |us| us.id == u.id }
      #      strength -= 1 if post.likes.detect{ |l| u.is_following_user?(l.id) }
      #
      #      updates = {"$inc" => { :strength => strength, :ds => strength }}
      #      updates["$pull"] = { :responses => post.id }
      #
      #      FeedUserItem.collection.update({:feed_id => u.id, :root_id => post.root_id}, updates, {:upsert => true})
      #    end
      #  end
      #  FeedUserItem.destroy_all(conditions: { :root_id => post.root_id, :strength => {"$lte" => 0} })
      #end
    end

    def follow(user, target)
      #if target.class.name == 'Topic'
      #  core_objects = Post.where('topic_mentions._id' => target.id)
      #else
      #  core_objects = Post.any_of({:user_id => target.id}, {'likes._id' => target.id})
      #end
      #core_objects.each do |post|
      #  unless user.id == post.user_snippet.id
      #    unless target.class.name == 'Topic' && post.class.name == 'Talk' && !post.is_popular
      #
      #      updates = {"$set" => { :root_type => post.root_type, :last_response_time => post.created_at }}
      #      updates["$addToSet"] = { :responses => post.id } unless post.is_root?
      #      updates["$inc"] = { :strength => 1, :ds => 1 }
      #
      #      FeedUserItem.collection.update({:feed_id => user.id, :root_id => post.root_id }, updates, {:upsert => true})
      #    end
      #  end
      #end
    end

    def unfollow(user, target)
      #if target.class.name == 'Topic'
      #  core_objects = Post.where('topic_mentions._id' => target.id)
      #else
      #  core_objects = Post.any_of({:user_id => target.id}, {'likes._id' => target.id})
      #end
      #core_objects.each do |post|
      #  unless user.id == post.user_snippet.id
      #    unless target.class.name == 'Topic' && post.class.name == 'Talk' && !post.is_popular
      #      keep = false
      #      unless post.is_root?
      #        keep = true if target.class.name == 'Topic' && user.is_following_user?(post.user_snippet.id) ||
      #                       post.user_mentions.detect{ |u| u.id == user.id } ||
      #                       post.likes.detect{ |l| l.id != target.id && user.is_following_user?(l.id) }
      #      end
      #
      #      updates = {"$inc" => { :strength => -1, :ds => -1 }}
      #      updates["$pull"] = { :responses => post.id } unless post.is_root? || keep
      #
      #      FeedUserItem.collection.update({:feed_id => user.id, :root_id => post.root_id }, updates)
      #    end
      #  end
      #end
      #FeedUserItem.destroy_all(conditions: { :feed_id => user.id, :strength => {"$lte" => 0} })
    end

    def like(user, post)

      # make the root post
      root_post = RootPost.new
      if post.is_root?
        root_post.root = post
      else
        root_post.root = post.root
      end

      root_post.public_talking = root_post.root.response_count

      user_feed_users = User.only(:id, :username, :following_users).where(:following_users => user.id)

      user_feed_users.each do |u|
        next if u.id == post.user_snippet.id

        item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

        new_push = false

        unless item
          new_push = true
          post.pushed_users << u.id.to_s
          post.pushed_users_count += 1
          item = FeedUserItem.new(:feed_id => u.id, :root_id => post.root_id)
        end

        item.root_type = post.root_type
        item.last_response_time = Time.now
        item.responses ||= []
        item.responses << post.id unless post.is_root?
        item.add_reason('lk', user)

        item.save if item.reasons.length > 0

        Pusher["#{u.id.to_s}_realtime"].trigger('new_post', root_post.to_json(:user => u)) if new_push
      end

      post.save

    end

    def unlike(user, post)
      user_feed_users = User.only(:id, :following_topics, :following_users).where(:following_users => user.id)

      user_feed_users.each do |u|
        next if u.id == post.user_snippet.id

        item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

        next unless item

        item.remove_reason('lk', user)

        if item.reasons.length == 0
          item.delete
        else
          item.save
        end
      end
    end

    def add_mention(post, topic_id)
      #user_feed_users = User.only(:id).where(:following_topics => topic_id)
      #
      #updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      #updates["$inc"] = { :strength => 1, :ds => 1 }
      #
      #user_feed_users.each do |u|
      #  unless u.id == post.user_snippet.id
      #    FeedUserItem.collection.update({:feed_id => u.id, :root_id => post.root_id}, updates, {:upsert => true})
      #  end
      #end
    end
  end
end
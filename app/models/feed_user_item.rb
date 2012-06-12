class FeedUserItem
  include Mongoid::Document

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

  index({ :root_id => -1, :feed_id => -1 }, { :unique => true })
  index({ :feed_id => -1, :last_response_time => -1 })
  index({ :feed_id => -1, :rel => -1 })
  index({ :responses => -1 })

  def created_at
    id.generation_time
  end

  def add_reason(type, target, target2=nil)
    self.reasons ||= []
    self.ds ||= 0
    unless reasons.detect{|r| r['t'] == type && r['id'] == target.id.to_s}
      reason = {
              't' => type,
              'n' => target.name ? target.name : target.username,
              's' => target.to_param,
              'id' => target.id.to_s
      }

      if target2
        reason['n2'] = target2.name
        reason['s2'] = target2.to_param
        reason['id2'] = target2.id.to_s
      end

      self.reasons << reason
      self.ds += 1
    end
  end

  def remove_reason(type, target)
    if reasons.detect{|r| r['t'] == type && r['id'] == target.id.to_s}
      self.reasons.delete_if{|r| r['t'] == type && r['id'] == target.id.to_s}
      self.ds -= 1
    end
  end

  class << self

    def push_post_through_users(post, single_user=nil, backlog=false)
      user_mention_ids = post.user_mentions.map{|um| um.id}

      # make the root post
      root_post = RootPost.new
      if post.is_root?
        root_post.root = post
      else
        root_post.root = post.root
        root_post.feed_responses << post
      end

      #root_post.public_talking = root_post.root.response_count

      # the potential users this post can be pushed to
      # take care of user mentions and users that are following the user that posted this
      if single_user
        user_feed_users = [single_user]
      else
        user_feed_users = User.only(:id, :following_topics, :following_users).any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_id}).to_a
        user_feed_users << post.user # add this post to this users own feed
      end


      # push to these users
      user_feed_users.each do |u|
        item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

        unless item
          post.pushed_users_count += 1
          item = FeedUserItem.new(:feed_id => u.id, :root_id => post.root_id)
          item.root_type = post.root_type
        end

        item.last_response_time = backlog ? post.created_at : Time.now
        item.responses ||= []
        item.responses << post.id unless post.is_root? || item.responses.include?(post.id)

        # add following user reason
        item.add_reason('fu', post.user) if u.following_users.include?(post.user_id)

        # add mentioned reason
        item.add_reason('m', post.user) if user_mention_ids.include?(u.id)

        # add created reason
        item.add_reason('c', post.user) if u.id == post.user_id

        item.save if item.reasons.length > 0

        root_post.push_item = item

        # if it's a new feed post, push it to the users feed
        unless backlog
          Pusher["#{u.id.to_s}_realtime"].trigger('new_post', root_post.to_json(:properties => :public))
        end
      end

      post.save
    end

    def push_post_through_topics(post)
      return if post.class.name == 'Talk'

      # push through topics
      post.topic_mentions.each do |topic|
        push_post_through_topic(post, topic)
      end
    end

    # used when a topic is added to a post (or by push_post_through_topics which goes through each topic mention and pushes through it)
    # optionally push for a single user
    def push_post_through_topic(post, push_topic, single_user=nil, backlog=false)
      return if post.class.name == 'Talk'

      neo4j_topic_ids = Neo4j.pulled_from_ids([push_topic.neo4j_id])
      topics = Topic.where(:_id => {"$in" => [push_topic.id] + neo4j_topic_ids.map{|t| t[1]}})

      # make the root post
      root_post = RootPost.new
      if post.is_root?
        root_post.root = post
      else
        root_post.root = post.root
        root_post.feed_responses << post
      end

      #root_post.public_talking = root_post.root.response_count

      topics.each do |topic|
        # the potential users this post can be pushed to
        if single_user
          user_feed_users = [single_user]
        else
          user_feed_users = User.only(:id, :following_topics).where(:following_topics => topic.id)
        end

        user_feed_users.each do |u|
          item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

          unless item
            post.pushed_users_count += 1
            item = FeedUserItem.new(:feed_id => u.id, :root_id => post.root_id)
            item.last_response_time = backlog ? post.created_at : Time.now
            item.root_type = post.root_type
          end

          item.responses ||= []
          item.responses << post.id unless post.is_root? || item.responses.include?(post.id)

          # add following topic reason
          if push_topic.id == topic.id && u.following_topics && u.following_topics.include?(topic.id)
            item.add_reason('ft', topic)
          elsif u.following_topics.include?(topic.id) # following topic related to another topic you're following
            item.add_reason('frt', topic, push_topic)
          end

          if item.reasons.length > 0
            item.save

            root_post.push_item = item

            # if it's a new feed post, push it to the users feed
            unless backlog
              Pusher["#{u.id.to_s}_realtime"].trigger('new_post', root_post.to_json(:properties => :short))
            end
          end
        end
      end

      post.save
    end

    # used when a topic is removed from a post
    def unpush_post_through_topic(post, unpush_topic, single_user=nil)
      return if post.class.name == 'Talk'

      neo4j_topic_ids = Neo4j.pulled_from_ids([unpush_topic.neo4j_id])
      topics = Topic.where(:_id => {"$in" => [unpush_topic.id] + neo4j_topic_ids.map{|t| t[1]}})

      topics.each do |topic|
        # the potential users this post can be pushed to
        if single_user
          user_feed_users = [single_user]
        else
          user_feed_users = User.only(:id, :following_topics).where(:following_topics => topic.id)
        end

        user_feed_users.each do |u|
          item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

          next unless item

          item.remove_reason('ft', topic)
          item.remove_reason('frt', topic)

          if item.reasons.length == 0
            item.delete
            post.pushed_users_count -= 1
          else
            item.save
          end

        end
      end

      post.save
    end

    def like(user, post)

      # make the root post
      root_post = RootPost.new
      if post.is_root?
        root_post.root = post
      else
        root_post.root = post.root
        root_post.feed_responses << post
      end

      #root_post.public_talking = root_post.root.response_count

      user_feed_users = User.only(:id, :username, :following_users).where(:following_users => user.id)

      user_feed_users.each do |u|
        next if u.id == post.user_id

        item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

        unless item
          post.pushed_users_count += 1
          item = FeedUserItem.new(:feed_id => u.id, :root_id => post.root_id)
        end

        item.root_type = post.root_type
        item.last_response_time = Time.now
        item.responses ||= []
        item.responses << post.id unless post.is_root?
        item.add_reason('lk', user)

        item.save if item.reasons.length > 0

        root_post.push_item = item

        Pusher["#{u.id.to_s}_realtime"].trigger('new_post', root_post.to_json(:properties => :short))
      end

      post.save

    end

    def unlike(user, post)
      user_feed_users = User.only(:id, :following_topics, :following_users).where(:following_users => user.id)

      user_feed_users.each do |u|
        next if u.id == post.user_id

        item = FeedUserItem.where(:feed_id => u.id, :root_id => post.root_id).first

        next unless item

        item.remove_reason('lk', user)

        if item.reasons.length == 0
          item.delete
          post.pushed_users_count -= 1
        else
          item.save
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
      if target.class.name == 'Topic'
        core_objects = Post.where(:topic_mention_ids => target.id).limit(10)
      else
        core_objects = Post.any_of({:user_id => target.id}, {:likes_ids => target.id}).limit(10)
      end
      core_objects.each do |post|
        if target.class.name == 'Topic'
          push_post_through_topic(post, target, user, true)
        else
          push_post_through_users(post, user, true)
        end
      end
    end

    def unfollow(user, target)
      #if target.class.name == 'Topic'
      #  core_objects = Post.where(:topic_mention_ids => target.id).limit(5)
      #else
      #  core_objects = Post.any_of({:user_id => target.id}, {:likes_ids => target.id}).limit(5)
      #end
      #core_objects.each do |post|
      #  if target.class.name == 'Topic'
      #    push_post_through_topic(post, target, user)
      #  else
      #    push_post_through_user(post, user)
      #  end
      #end

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
  end
end
class PushPostToFeeds

  @queue = :medium

  def self.perform(object_id, user_id=nil, topic_id=nil)
    object = PostMedia.find(object_id)

    if object
      if user_id
        user = User.find(user_id)
        if user
          share = object.get_share(user.id)
          share.push_to_feeds if share
        end
      else
        if topic_id
          topic = Topic.find(topic_id)
          if topic
            object.push_to_feeds(topic)
          end
        else
          object.push_to_feeds
        end
      end
    end
  end
end
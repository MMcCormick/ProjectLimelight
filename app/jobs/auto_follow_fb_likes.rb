class AutoFollowFBLikes
  @queue = :fast

  def self.perform(user_id)
    user = User.find(user_id)
    if user
      fb = user.facebook
      if fb
        type_connection = TopicConnection.find(Topic.type_of_id)
        likes = fb.get_connections("me", "likes")
        likes.each do |like|
          fb_page = fb.get_object(like['id'])
          next if !fb_page || fb_page['likes'] < 500

          topic = Topic.where("aliases.slug" => like['name'].to_url).order_by(:score, :desc).first
          type = Topic.where("aliases.slug" => like['category'].to_url).order_by(:score, :desc).first

          unless type
            type = Topic.new
            type.name = like['category']
            type.save
          end

          unless topic
            topic = Topic.new
            topic.name = like['name']
          end

          topic.website = fb_page['website'] unless topic.website
          topic.fb_page_id = fb_page['id']
          topic.summary = fb_page['about'] unless topic.summary
          topic.user_id = User.marc_id unless topic.user_id

          if topic.image_versions.to_i == 0 && fb_page['picture']
            topic.remote_image_url = fb_page['picture']
            topic.save_remote_image(true)
          end

          saved = topic.save

          if saved
            unless topic.primary_type_id
              TopicConnection.add(type_connection, topic, type, User.marc_id, {:pull => false, :reverse_pull => true})
            end

            user.follow_object(topic)
          end
        end
        user.save :validate => false # skip validation because a user has no username after they signup with FB
      end
    end
  end
end
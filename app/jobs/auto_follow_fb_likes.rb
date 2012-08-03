class AutoFollowFBLikes
  @queue = :fast_limelight

  def self.perform(user_id)
    user = User.find(user_id)
    if user
      fb = user.facebook
      if fb
        likes = fb.get_connections("me", "likes")
        likes.each do |like|
          fb_page = fb.get_object(like['id'])
          next if !fb_page || fb_page['likes'] < 500

          topic = Topic.where("aliases.slug" => like['name'].parameterize).desc(:score).first

          #unless topic
          #  # check freebase if there is no freebase id returned from alchemy api
          #  search = HTTParty.get("https://www.googleapis.com/freebase/v1/search?lang=en&limit=3&query=#{like['name']}")
          #  next unless search && search['result'] && search['result'].first && ((search['result'].first['notable'] && search['result'].first['score'] >= 50) || search['result'].first['score'] >= 200)
          #
          #  topic = Topic.where("aliases.slug" => like['name'].parameterize).desc(:score).first
          #  type = Topic.where("aliases.slug" => like['category'].parameterize).desc(:score).first
          #
          #  unless type
          #    type = Topic.new
          #    type.name = like['category']
          #    type.user_id = User.marc_id
          #    type.save
          #  end
          #
          #  unless topic
          #    topic = Topic.new
          #    topic.name = like['name']
          #  end
          #
          #  topic.website = fb_page['website'] unless topic.website
          #  topic.fb_page_id = fb_page['id']
          #  topic.summary = fb_page['about'] unless topic.summary
          #  topic.user_id = User.marc_id unless topic.user_id
          #
          #  if topic.images.length.to_i == 0 && fb_page['picture']
          #    topic.save_remote_image(fb_page['picture'], true)
          #  end
          #
          #  saved = topic.save
          #
          #  if saved
          #    unless topic.primary_type_id
          #      topic.primary_type_id = type.id
          #      topic.primary_type = type.name
          #      topic.save
          #      TopicConnection.add(type_connection, topic, type, User.marc_id, {:pull => false, :reverse_pull => true})
          #    end
          #  else
          #    next
          #  end
          #end

          if topic
            if topic.images.length.to_i == 0 && fb_page['picture']
              topic.save_remote_image(fb_page['picture'])
            end
            topic.fb_page_id = fb_page['id']
            topic.website = fb_page['website'] unless topic.website
            topic.summary = fb_page['about'] unless topic.summary
            topic.user_id = User.marc_id unless topic.user_id
            topic.save
            user.follow_object(topic)
          end

        end
        user.save :validate => false # skip validation because a user has no username after they signup with FB
      end
    end
  end
end
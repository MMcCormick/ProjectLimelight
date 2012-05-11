class AutoFollowFBLikes
  @queue = :fast

  def self.perform(user_id)
    user = User.find(user_id)
    if user
      fb = user.facebook
      if fb
        likes = fb.get_connections("me", "likes")
        likes.each do |like|
          topic = Topic.where("aliases.slug" => like['name'].to_url).order_by(:score, :desc).first
          if topic
            user.follow_object(topic)
          end
        end
        user.save :validate => false # skip validation because a user has no username after they signup with FB
      end
    end
  end
end
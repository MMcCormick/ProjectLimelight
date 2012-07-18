class PushPostToFeeds

  @queue = :medium

  def self.perform(object_id, user_id)
    object = PostMedia.find(object_id)
    user = User.find(user_id)
    if object && user
      share = object.get_share(user.id)
      share.push_to_feeds if share
    end
  end
end
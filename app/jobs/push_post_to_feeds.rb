class PushPostToFeeds

  @queue = :feeds

  def self.perform(object_id)
    object = Post.find(object_id)
    object.push_to_feeds if object
  end
end
class PushPostToFeeds

  @queue = :feeds

  def self.perform(object_id)
    object = CoreObject.find(object_id)
    object.push_to_feeds if object
  end
end
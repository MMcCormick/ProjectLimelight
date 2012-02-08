class PushUnlike

  @queue = :feeds

  def self.perform(object_id, user_id)
    object = CoreObject.find(object_id)
    user = User.find(user_id)
    object.push_unlike(user) if object && user
  end
end
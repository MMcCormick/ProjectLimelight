class PushLike

  @queue = :feeds

  def self.perform(object_id, user_id)
    object = CoreObject.find(object_id)
    user = User.find(user_id)
    object.push_like(user) if object && user    d
  end
end
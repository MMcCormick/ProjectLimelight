class PushUnlike

  @queue = :medium

  def self.perform(object_id, user_id)
    object = Post.find(object_id)
    user = User.find(user_id)
    object.push_unlike(user) if object && user
  end
end
class PushPostDisable

  @queue = :medium

  def self.perform(object_id)
    object = Post.find(object_id)
    object.push_disable if object
  end
end
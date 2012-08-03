class PushPostDisable

  @queue = :medium_limelight

  def self.perform(object_id)
    object = Post.find(object_id)
    object.push_disable if object
  end
end
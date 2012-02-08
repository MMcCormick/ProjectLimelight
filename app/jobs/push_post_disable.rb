class PushPostDisable

  @queue = :feeds

  def self.perform(object_id)
    object = CoreObject.find(object_id)
    object.push_disable if object
  end
end
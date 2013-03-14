class PushPostDisable

  include Sidekiq::Worker
  sidekiq_options :queue => :medium_limelight

  def perform(object_id)
    object = Post.find(object_id)
    object.push_disable if object
  end
end
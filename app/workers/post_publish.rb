class PostPublish

  include Sidekiq::Worker
  sidekiq_options :queue => :medium_limelight

  def perform(post_id)
    post = PostMedia.unscoped.find(post_id)
    if post
      post.publish
      post.publish_shares
      post.save
      post.expire_cached_json
    end
  end
end
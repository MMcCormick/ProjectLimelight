class Neo4jShareCreate

  include Sidekiq::Worker
  sidekiq_options :queue => :neo4j_limelight

  def perform(post_id, user_id)
    post = PostMedia.find(post_id)
    user = User.find(user_id)
    Neo4j.share_create(post, user) if post && user
  end
end
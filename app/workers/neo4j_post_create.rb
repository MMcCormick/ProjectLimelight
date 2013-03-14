class Neo4jPostCreate

  include Sidekiq::Worker
  sidekiq_options :queue => :neo4j_limelight

  def perform(post_id)
    post = Post.find(post_id)
    Neo4j.post_create(post) if post
  end
end
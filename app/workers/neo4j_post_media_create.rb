class Neo4jPostMediaCreate

  include Sidekiq::Worker
  sidekiq_options :queue => :neo4j_limelight

  def perform(post_media_id)
    post_media = PostMedia.find(post_media_id)
    Neo4j.post_media_create(post_media) if post_media
  end
end
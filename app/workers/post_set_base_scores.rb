class PostSetBaseScores

  include Sidekiq::Worker
  sidekiq_options :queue => :neo4j_limelight

  def perform(post_id)
    post = PostMedia.unscoped.find(post_id)
    if post
      post.set_base_scores
      post.calculate_score
      post.save
    end
  end
end
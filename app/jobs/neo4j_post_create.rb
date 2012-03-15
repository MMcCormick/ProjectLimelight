class Neo4jPostCreate

  @queue = :slow

  def self.perform(post_id)
    post = Post.find(post_id)
    Neo4j.post_create(post) if post
  end
end
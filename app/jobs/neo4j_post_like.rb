class Neo4jPostLike

  @queue = :neo4j

  def self.perform(user_id, post_id)
    Neo4j.post_like(user_id, post_id)
  end
end
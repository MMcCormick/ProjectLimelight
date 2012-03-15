class Neo4jPostUnlike

  @queue = :neo4j

  def self.perform(user_id, post_id)
    Neo4j.post_unlike(user_id, post_id)
  end
end
class Neo4jPostCreate

  @queue = :neo4j

  def self.perform(post_id)
    post = CoreObject.find(post_id)
    Neo4j.post_create(post) if post
  end
end
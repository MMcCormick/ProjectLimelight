class Neo4jPostAction

  @queue = :neo4j

  def self.perform(user_id, post_id, change)
    Neo4j.post_action(user_id, post_id, change)
  end
end
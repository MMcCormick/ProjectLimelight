class Neo4jFollowCreate

  @queue = :neo4j

  def self.perform(node1_id, node2_id)
    Neo4j.follow_destroy(node1_id, node2_id)
  end
end
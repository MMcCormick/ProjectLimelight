class Neo4jFollowDestroy

  @queue = :neo4j

  def self.perform(node1_id, node2_id, node1_index, node2_index)
    Neo4j.follow_destroy(node1_id, node2_id, node1_index, node2_index)
  end
end
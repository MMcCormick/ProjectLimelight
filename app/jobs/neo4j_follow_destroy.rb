require 'json'

class Neo4jFollowDestroy

  @queue = :neo4j

  def self.perform(node1_id, node2_id)
    rel1 = Neo4j.neo.get_relationship_index('user-relationships', 'follow', "#{node1_id}-#{node2_id}")
    Neo4j.neo.delete_relationship(rel1)
    Neo4j.neo.remove_relationship_from_index('user-relationships', rel1)

    Neo4j.update_affinity(node1_id, node2_id, nil, nil, -10, false, nil)
  end

end
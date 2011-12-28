require 'json'

class Neo4jFollowCreate

  @queue = :neo4j

  def self.perform(node1_id, node2_id, node1_index, node2_index)
    node1 = Neo4j.neo.get_node_index(node1_index, 'id', node1_id)
    node2 = Neo4j.neo.get_node_index(node2_index, 'id', node2_id)
    rel1 = Neo4j.neo.create_relationship('follow', node1, node2)
    Neo4j.neo.add_relationship_to_index('users', 'follow', "#{node1_id}-#{node2_id}", rel1)
    Neo4j.update_affinity(node1_id, node2_id, node1, node2, 50, false, nil)
  end

end
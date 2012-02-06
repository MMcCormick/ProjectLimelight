#require 'json'
#
#class Neo4jFollowDestroy
#
#  @queue = :neo4j
#
#  def self.perform(node1_id, node2_id)
#    rel1 = Neo4j.neo.get_relationship_index('users', 'follow', "#{node1_id}-#{node2_id}")
#    Neo4j.neo.delete_relationship(rel1)
#    Neo4j.neo.remove_relationship_from_index('users', rel1)
#
#    Neo4j.update_affinity(node1_id, node2_id, nil, nil, -50, false, nil, nil, false)
#  end
#
#end
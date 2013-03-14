class Neo4jFollowCreate

  include Sidekiq::Worker
  sidekiq_options :queue => :neo4j_limelight

  def perform(node1_id, node2_id, node1_index, node2_index)
    Neo4j.follow_create(node1_id, node2_id, node1_index, node2_index)
  end
end
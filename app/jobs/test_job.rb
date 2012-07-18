class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()
    users = User.all

    users.each do |user|
      user.topic_activity_recalculate()
      user.save

      node = Neo4j.neo.get_node(user.neo4j_id)
      rels = Neo4j.neo.get_node_relationships(node, 'out', 'talking')
      if rels
        rels.each do |rel|
          Neo4j.neo.delete_relationship(rel)
        end
      end
      PostMedia.where("shares.user_id" => user.id).each do |pm|
        share = pm.get_share(user.id)
        share.topic_mentions.each do |t|
          Neo4j.update_talk_count(user, t, 1, node, nil, pm.id)
        end
      end
    end

  end
end
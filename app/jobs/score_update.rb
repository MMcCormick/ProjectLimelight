# updates the score in neo4j and soulmate (if applicable) for main objects when their score changes
class ScoreUpdate
  include Resque::Plugins::UniqueJob

  @queue = :slow

  def self.perform(target_type, target_id)
    target = Kernel.const_get(target_type).find(target_id)
    if target
      if target.class.name == 'Topic'
        Resque.enqueue(SmCreateTopic, target.id.to_s)
      elsif target.class.name == 'User'
        Resque.enqueue(SmCreateUser, target.id.to_s)
      end

      node = Neo4j.neo.get_node_index(target_type.downcase.pluralize, 'uuid', target.id.to_s)
      Neo4j.neo.set_node_properties(node, {'score' => target.score}) if node
    end
  end
end
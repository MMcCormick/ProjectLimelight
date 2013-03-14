# updates the score in neo4j and soulmate (if applicable) for main objects when their score changes
class ScoreUpdate
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform(target_type, target_id)
    target = Kernel.const_get(target_type).find_by_slug_id(target_id)
    if target
      if target.class.name == 'Topic'
        SmCreateTopic.perform_async(target.id.to_s)
      elsif target.class.name == 'User'
        SmCreateUser.perform_async(target.id.to_s)
      end

      node = Neo4j.neo.get_node_index(target_type.downcase.pluralize, 'uuid', target.id.to_s)
      Neo4j.neo.set_node_properties(node, {'score' => target.score}) if node
    end
  end
end
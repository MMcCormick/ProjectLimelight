class Neo4j

  class << self
    def neo
      @neo ||= ENV['NEO4J_REST_URL'] ? Neography::Rest.new(ENV['NEO4J_REST_URL']) : Neography::Rest.new
    end

    def update_affinity(node1_id, node2_id, node1, node2, change, mutual, with_connection)
      affinity = self.neo.get_relationship_index('affinity', 'nodes', "#{node1_id}-#{node2_id}")
      if affinity
        properties = self.neo.get_relationship_properties(affinity, 'weight')
        if properties['weight'] + change == 0
          self.neo.delete_relationship(affinity)
          self.neo.remove_relationship_from_index('affinity', affinity)
        else
          update = {'weight' => properties['weight']+change}
          update['with_connection'] = with_connection if with_connection
          self.neo.set_relationship_properties(affinity, update)
        end
      elsif node1 && node2
        affinity = self.neo.create_relationship('affinity', node1, node2)
        self.neo.set_relationship_properties(affinity, {'weight' => change, 'mutual' => mutual, 'with_connection' => with_connection})
        self.neo.add_relationship_to_index('affinity', 'nodes', "#{node1_id}-#{node2_id}", affinity)
        if mutual == true
          self.neo.add_relationship_to_index('affinity', 'nodes', "#{node2_id}-#{node1_id}", affinity)
        end
      end
    end
  end

end
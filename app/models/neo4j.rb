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

    def get_topic_relationships(topic_id)
      query = "
        START n=node:topics(id = '#{topic_id.to_s}')
        MATCH (n)-[r]->(x)
        WHERE r.connection_id
        RETURN r,x
      "
      outgoing = Neo4j.neo.execute_query(query)

      query = "
        START n=node:topics(id = '#{topic_id.to_s}')
        MATCH (n)<-[r]-(x)
        WHERE r.connection_id
        RETURN r,x
      "
      incoming = Neo4j.neo.execute_query(query)

      organized = {}

      if outgoing
        outgoing['data'].each do |c|
          type = c[0]['type']
          organized[type] ||= {'relationship' => c[0]['data'], 'connection_id' => c[0]['data']['connection_id'], 'connections' => []}
          organized[type]['connections'] << c[1]['data']
        end
      end

      if incoming
        incoming['data'].each do |c|
          type = c[0]['data']['reverse_name'].blank? ? c[0]['type'] : c[0]['data']['reverse_name']
          organized[type] ||= {'relationship' => c[0]['data'], 'connection_id' => c[0]['data']['connection_id'], 'connections' => []}
          organized[type]['connections'] << c[1]['data']
        end
      end

      organized
    end

    def pull_from_ids(topic_id)
      query = "
        START n=node:topics(id = '#{topic_id}')
        MATCH n-[:pull*]->x
        WHERE x.id != '#{topic_id}'
        RETURN distinct x.id
      "
      ids = Neo4j.neo.execute_query(query)
      pull_from = []
      ids['data'].each do |id|
        pull_from << BSON::ObjectId(id[0])
      end
      pull_from
    end

    def user_interests(user_id, limit)
      query = "
        START n=node:users(id = k cya'#{user_id}')
        MATCH n-[r1:affinity]->topic
        WHERE topic.type = 'topic' AND r1.weight >= 50
        RETURN topic
        ORDER BY r1.weight desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      interests = []
      ids['data'].each do |n|
        interests << n[0]['data']
      end
      interests
    end

    def user_topic_suggestions(user_id, limit)
      query = "
        START user=node:users(id = '#{user_id}')
        MATCH user-[r1:affinity]->topic-[r2:affinity]-suggestion
        WHERE (topic.type = 'topic' AND suggestion.type = 'topic' AND r1.weight >= 50) AND NOT(user-[:follow]->suggestion)
        RETURN suggestion
        ORDER BY r2.weight desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      suggestions = []
      ids['data'].each do |n|
        suggestions << n[0]['data']
      end
      suggestions
    end
  end

end
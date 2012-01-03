class Neo4j

  class << self
    def neo
      @neo ||= ENV['NEO4J_URL'] ? Neography::Rest.new(ENV['NEO4J_URL']) : Neography::Rest.new
    end

    # creates a follow relationship between two nodes
    def follow_create(node1_id, node2_id, node1_index, node2_index)
      node1 = self.neo.get_node_index(node1_index, 'id', node1_id)
      node2 = self.neo.get_node_index(node2_index, 'id', node2_id)
      rel1 = self.neo.create_relationship('follow', node1, node2)
      self.neo.add_relationship_to_index('users', 'follow', "#{node1_id}-#{node2_id}", rel1)
      self.update_affinity(node1_id, node2_id, node1, node2, 50, false, nil)

      # remove negative direction (if present)
      old_direction = self.neo.get_relationship_index('sentiment', 'direction', "#{node1_id}-#{node2_id}")
      if old_direction && old_direction[0]['type'] == 'negative'
        self.neo.delete_relationship(old_direction)
        self.neo.remove_relationship_from_index('sentiment', old_direction)
      end

    end

    # updates the affinity between two nodes
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

    # get a topic's relationships. sort them into two groups, outgoing and incoming
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

    # get a topics pull from ids
    def pull_from_ids(topic_id)
      query = "
        START n=node:topics(id = '#{topic_id}')
        MATCH n-[:pull*]->x
        WHERE x.id != '#{topic_id}'
        RETURN distinct x.id
      "
      ids = Neo4j.neo.execute_query(query)
      pull_from = []
      if ids
        ids['data'].each do |id|
          pull_from << BSON::ObjectId(id[0])
        end
      end
      pull_from
    end

    # user interests, used in the user sidebar
    def user_interests(user_id, limit)
      interests = {:general => [], :specific => []}

      # tally up what types are generally connected to topics this user likes
      query = "
        START n=node:users(id = '#{user_id}')
        MATCH n-[:affinity]->topic-[r2:`Type Of`]->type
        WHERE topic.type = 'topic'
        RETURN type, COUNT(r2)
        ORDER BY count(r2) desc
        LIMIT 10
      "
      ids = self.neo.execute_query(query)
      if ids
        ids['data'].each do |n|
          interests[:general] << {
                  :data => n[0]['data'],
                  :weight => n[1]
          }
        end
      end

      # tally up a users specific interests
      query = "
        START n=node:users(id = '#{user_id}')
        MATCH n-[r1:affinity]->topic
        WHERE topic.type = 'topic' AND r1.weight >= 50
        RETURN topic, r1.weight as weight
        ORDER BY r1.weight desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      if ids
        ids['data'].each do |n|
          interests[:specific] << {
                  :data => n[0]['data'],
                  :weight => n[1]
          }
        end
      end

      interests
    end

    # topic suggestions, used in the user sidebar and topic finder
    def user_topic_suggestions(user_id, limit)
      query = "
        START user=node:users(id = '#{user_id}')
        MATCH user-[r1:affinity]->topic<-[r2:affinity]-user2-[r3:affinity]->suggestion
        WHERE topic.type = 'topic' AND user2.type = 'user' AND suggestion.type = 'topic' AND r1.weight >= 50 AND r2.weight >= 50 AND NOT(user-[:follow]->suggestion OR user-[:negative]->topic OR user-[:negative]->suggestion)
        RETURN suggestion, SUM(r3.weight)
        ORDER BY SUM(r3.weight) desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      suggestions = []
      if ids
        ids['data'].each do |n|
          suggestions << n[0]['data']
        end
      end
      suggestions
    end

    # related topic, used in the topic sidebar
    def topic_related(topic_id, limit)
      query = "
        START topic=node:topics(id = '#{topic_id}')
        MATCH topic-[r:affinity]-related
        WHERE related.type = 'topic'
        RETURN related, SUM(r.weight)
        ORDER BY SUM(r.weight) desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      suggestions = []
      if ids
        ids['data'].each do |n|
          suggestions << n[0]['data']
        end
      end
      suggestions
    end

    def get_sentiment(node1_id, node2_id)
      self.neo.get_relationship_index('sentiment', 'name', "#{node1_id}-#{node2_id}")
    end

    def toggle_sentiment(node1_index, node1_id, node2_index, node2_id, direction, sentiment)

      # remove the old sentiment and direction (if present)
      old_sentiment = self.neo.get_relationship_index('sentiment', 'name', "#{node1_id}-#{node2_id}")
      if old_sentiment
        self.neo.delete_relationship(old_sentiment)
        self.neo.remove_relationship_from_index('sentiment', old_sentiment)
      end
      old_direction = self.neo.get_relationship_index('sentiment', 'direction', "#{node1_id}-#{node2_id}")
      if old_direction
        self.neo.delete_relationship(old_direction)
        self.neo.remove_relationship_from_index('sentiment', old_direction)
      end

      # add the new sentiment and direction
      if sentiment || direction
        node1 = self.neo.get_node_index(node1_index, 'id', node1_id)
        node2 = self.neo.get_node_index(node2_index, 'id', node2_id)
        if sentiment
          new_sentiment = self.neo.create_relationship(sentiment, node1, node2)
          self.neo.add_relationship_to_index('sentiment', 'name', "#{node1_id}-#{node2_id}", new_sentiment)
        end
        if direction
          new_direction = self.neo.create_relationship(direction, node1, node2)
          self.neo.add_relationship_to_index('sentiment', 'direction', "#{node1_id}-#{node2_id}", new_direction)
        end
      end

    end
  end

end
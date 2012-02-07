class Neo4j

  class << self

    include TorqueBox::Messaging::Backgroundable

    def neo
      @neo ||= ENV['NEO4J_URL'] ? Neography::Rest.new(ENV['NEO4J_URL']) : Neography::Rest.new
    end

    # called for post actions (like, favorite, etc)
    always_background :post_action
    def post_action(user_id, post_id, change)
      node1 = Neo4j.neo.get_node_index('users', 'uuid', user_id)
      post = CoreObject.find(post_id)

      if node1 && post
        # increase affinity to the post creator
        node2 = Neo4j.neo.get_node_index('users', 'uuid', post.user_id.to_s)
        Neo4j.update_affinity(user_id, post.user_id.to_s, node1, node2, change*2, false, nil) if node2

        # increase affinity to mentioned users
        post.user_mentions.each do |m|
          node2 = Neo4j.neo.get_node_index('users', 'uuid', m.id.to_s)
          Neo4j.update_affinity(user_id, m.id.to_s, node1, node2, change, false, nil) if node2
        end

        # increase affinity to mentioned topics
        post.topic_mentions.each do |m|
          node2 = Neo4j.neo.get_node_index('topics', 'uuid', m.id.to_s)
          Neo4j.update_affinity(user_id, m.id.to_s, node1, node2, change, false, nil) if node2
        end
      end
    end

    always_background :post_create
    def post_create(post)
      creator_node = Neo4j.neo.get_node_index('users', 'uuid', post.user_id.to_s)

      post_node = Neo4j.neo.get_node_index('posts', 'uuid', post.id.to_s)
      unless post_node
        post_node = Neo4j.neo.create_node(
                'uuid' => post.id.to_s,
                'type' => 'post',
                'subtype' => post.class.name,
                'public_id' => post.public_id
        )
        Neo4j.neo.add_node_to_index('posts', 'uuid', post.id.to_s, post_node)
      end

      rel1 = Neo4j.neo.create_relationship('created', creator_node, post_node)
      Neo4j.neo.add_relationship_to_index('users', 'created', "#{post.user_id.to_s}-#{post.id.to_s}", rel1)

      post.user_mentions.each do |m|
        # connect the post to it's mentioned users
        mention_node = Neo4j.neo.get_node_index('users', 'uuid', m.id.to_s)
        rel2 = Neo4j.neo.create_relationship('mentions', post_node, mention_node)
        Neo4j.neo.set_relationship_properties(rel2, {"type" => 'user'})
        Neo4j.neo.add_relationship_to_index('posts', 'mentions', "#{post.id.to_s}-#{m.id.to_s}", rel2)

        # increase the creators affinity to these users
        Neo4j.update_affinity(post.user_id.to_s, m.id.to_s, creator_node, mention_node, 10, false, false)
      end

      topics = []
      post.topic_mentions.each do |m|
        # connect the post to it's mentioned topics
        mention_node = Neo4j.neo.get_node_index('topics', 'uuid', m.id.to_s)
        rel2 = Neo4j.neo.create_relationship('mentions', post_node, mention_node)
        Neo4j.neo.set_relationship_properties(rel2, {"type" => 'topic'})
        Neo4j.neo.add_relationship_to_index('posts', 'mentions', "#{post.id.to_s}-#{m.id.to_s}", rel2)

        # increase the creators affinity to these topics
        Neo4j.update_affinity(post.user_id.to_s, m.id.to_s, creator_node, mention_node, 10, false, false)

        topics << {:node => mention_node, :node_id => m.id.to_s}
      end

      if post.response_to
        parent_node = Neo4j.neo.get_node_index('posts', 'uuid', post.response_to.id.to_s)
        if parent_node
          talk_rel = Neo4j.neo.create_relationship('talked', creator_node, parent_node)
          Neo4j.neo.set_relationship_properties(talk_rel, {"created_at" => Time.now})
          Neo4j.neo.add_relationship_to_index('users', 'talked', "#{post.user_id.to_s}-#{post.response_to.id.to_s}", talk_rel)
        end
      end

      # increase the mentioned topics affinities towards each other
      topics.combination(2).to_a.each do |t|
        Neo4j.update_affinity(t[0][:node_id], t[1][:node_id], t[0][:node], t[1][:node], 2, true, nil)
      end
    end

    # creates a follow relationship between two nodes
    always_background :follow_create
    def follow_create(node1_id, node2_id, node1_index, node2_index)
      #nodes = self.neo.batch [:get_node_by_index, node1_index, "uuid", node1_id], [:get_node_by_index, node2_index, "uuid", node2_id]
      #self.neo.batch [:create_relationship, "follow", nodes[0]['body'].first['self'].split('/').last, nodes[1]['body'].first['self'].split('/').last],
      #               [:add_relationship_to_index, "users", "follow", "#{node1_id}-#{node2_id}", "{0}"] if nodes && nodes.length == 2
      #self.update_affinity(node1_id, node2_id, nodes[0]['body'].first, nodes[1]['body'].first, 50, false, nil, 'positive', false) if nodes && nodes.length == 2
      node1 = self.neo.get_node_index(node1_index, 'uuid', node1_id)
      node2 = self.neo.get_node_index(node2_index, 'uuid', node2_id)
      if node1 && node2
        follow = self.neo.create_relationship('follow', node1, node2)
        self.neo.add_relationship_to_index('users', 'follow', "#{node1_id}-#{node2_id}", follow) if follow
        self.update_affinity(node1_id, node2_id, node1, node2, 50, false, nil, 'positive', false) if follow
      end
    end

    always_background :follow_destroy
    def follow_destroy(node1_id, node2_id)
      rel1 = Neo4j.neo.get_relationship_index('users', 'follow', "#{node1_id}-#{node2_id}")
      Neo4j.neo.delete_relationship(rel1)
      Neo4j.neo.remove_relationship_from_index('users', rel1)

      Neo4j.update_affinity(node1_id, node2_id, nil, nil, -50, false, nil, nil, false)
    end

    # updates the affinity between two nodes
    def update_affinity(node1_id, node2_id, node1, node2, change=0, mutual=nil, with_connection=nil, sentiment='none', overrideSentiment=true)
      affinity = self.neo.get_relationship_index('affinity', 'nodes', "#{node1_id}-#{node2_id}")
      if affinity
        payload = {}
        if change
          properties = self.neo.get_relationship_properties(affinity)
          weight = properties && properties['weight'] ? properties['weight'] : 0
          if weight + change == 0
            self.neo.delete_relationship(affinity)
            self.neo.remove_relationship_from_index('affinity', affinity)
          else
            payload['weight'] = weight+change
            payload['with_connection'] = with_connection if with_connection
          end
        end

        if sentiment
          if (!properties || !properties['sentiment'] || properties['sentiment'] == 'none') || overrideSentiment == true
            payload['sentiment'] = sentiment
          end
        end

        self.neo.set_relationship_properties(affinity, payload) if payload.length > 0
      else
        unless node1 && node2
          node1 = self.neo.get_node_index(node1_index, 'uuid', node1_id)
          node2 = self.neo.get_node_index(node2_index, 'uuid', node2_id)
        end

        affinity = self.neo.create_relationship('affinity', node1, node2)
        self.neo.set_relationship_properties(affinity, {
                'weight' => change,
                'mutual' => mutual,
                'with_connection' => with_connection,
                'sentiment' => sentiment
        })
        self.neo.add_relationship_to_index('affinity', 'nodes', "#{node1_id}-#{node2_id}", affinity)
        if mutual == true
          self.neo.add_relationship_to_index('affinity', 'nodes', "#{node2_id}-#{node1_id}", affinity)
        end
      end
    end

    def update_sentiment(node1_id, node1_index, node2_id, node2_index, sentiment, overrideSentiment=true)
      node1 = self.neo.get_node_index(node1_index, 'uuid', node1_id)
      node2 = self.neo.get_node_index(node2_index, 'uuid', node2_id)
      update_affinity(node1_id, node2_id, node1, node2, nil, nil, nil, sentiment, overrideSentiment)
    end

    # get a topic's relationships. sort them into two groups, outgoing and incoming
    def get_topic_relationships(topic_id)
      query = "
        START n=node:topics(uuid = '#{topic_id.to_s}')
        MATCH (n)-[r]->(x)
        WHERE r.connection_id
        RETURN r,x
      "
      outgoing = Neo4j.neo.execute_query(query)

      query = "
        START n=node:topics(uuid = '#{topic_id.to_s}')
        MATCH (n)<-[r]-(x)
        WHERE r.connection_id
        RETURN r,x
      "
      incoming = Neo4j.neo.execute_query(query)

      organized = {}

      if outgoing
        outgoing['data'].each do |c|
          type = c[0]['type']
          organized[type] ||= c[0]['data'].select{|key,value|['connection_id','reverse_name','inline'].include?(key)}.merge({'connections' => []})
          organized[type]['connections'] << c[0]['data'].select{|key,value|['pull','reverse_pull','user_id'].include?(key)}.merge(c[1]['data'])
        end
      end

      if incoming
        incoming['data'].each do |c|
          type = c[0]['data']['reverse_name'].blank? ? c[0]['type'] : c[0]['data']['reverse_name']
          organized[type] ||= c[0]['data'].select{|key,value|['connection_id','reverse_name','inline'].include?(key)}.merge({'connections' => []})
          organized[type]['connections'] << c[0]['data'].select{|key,value|['pull','reverse_pull','user_id'].include?(key)}.merge(c[1]['data'])
          #organized[type] ||= {'relationship' => c[0]['data'], 'connection_id' => c[0]['data']['connection_id'], 'connections' => []}
          #organized[type]['connections'] << c[1]['data']
        end
      end

      # sort by number of connected topics
      organized = organized.sort do |a,b|
        b[1]["connections"].length <=> a[1]["connections"].length
      end

      # put type at the beginning
      type_of_index = organized.index{ |con| con[1]["connection_id"] == Topic.type_of_id }
      organized.unshift(organized.delete_at(type_of_index)) if type_of_index

      organized
    end

    # get a topics pull from ids
    def pull_from_ids(topic_id)
      query = "
        START n=node:topics(uuid = '#{topic_id}')
        MATCH n-[:pull*]->x
        WHERE x.uuid != '#{topic_id}'
        RETURN distinct x.uuid
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
      #query = "
      #  START n=node:users(uuid = '#{user_id}')
      #  MATCH n-[:affinity]->topic-[r2:`Type Of`]->type
      #  WHERE topic.type = 'topic'
      #  RETURN type, COUNT(r2)
      #  ORDER BY count(r2) desc
      #  LIMIT 10
      #"
      #ids = self.neo.execute_query(query)
      #if ids
      #  ids['data'].each do |n|
      #    n[0]['data']['id'] = n[0]['data']['uuid']
      #    interests[:general] << {
      #            :data => n[0]['data'],
      #            :weight => n[1]
      #    }
      #  end
      #end

      # tally up a users specific interests
      query = "
        START n=node:users(uuid = '#{user_id}')
        MATCH n-[r1:affinity]->topic
        WHERE topic.type = 'topic' and r1.weight and r1.weight >= 50
        RETURN topic, r1.weight
        ORDER BY r1.weight desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      if ids
        ids['data'].each do |n|
          n[0]['data']['id'] = n[0]['data']['uuid']
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
        START user=node:users(uuid = '#{user_id}')
        MATCH user-[r1:affinity]->topic<-[r2:affinity]-user2-[r3:affinity]->suggestion, user-[r4?:affinity]->suggestion, user-[r5?:follow]->suggestion
        WHERE topic.type = 'topic' and user2.type = 'user' and suggestion.type = 'topic' and r1.weight and r1.weight >= 10 and r3.weight and (r1.sentiment != 'negative') and (r4 IS NULL) and r5 IS NULL
        RETURN suggestion, SUM(r3.weight)
        ORDER BY SUM(r3.weight) desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      suggestions = []
      if ids
        ids['data'].each do |n|
          n[0]['data']['id'] = n[0]['data']['uuid']
          suggestions << n[0]['data']
        end
      end
      suggestions
    end

    # related topic, used in the topic sidebar
    def topic_related(topic_id, limit)
      query = "
        START topic=node:topics(uuid = '#{topic_id}')
        MATCH topic-[r:affinity]-related
        WHERE related.type = 'topic' and r.weight
        RETURN related, SUM(r.weight)
        orDER BY SUM(r.weight) desc
        LIMIT #{limit}
      "
      ids = self.neo.execute_query(query)
      suggestions = []
      if ids
        ids['data'].each do |n|
          n[0]['data']['id'] = n[0]['data']['uuid']
          suggestions << n[0]['data']
        end
      end
      suggestions
    end

    def get_sentiment(node1_id, node2_id)
      self.neo.get_relationship_index('sentiment', 'name', "#{node1_id}-#{node2_id}")
    end

    def get_connection(con_id, topic1_id, topic2_id)
      Neo4j.neo.get_relationship_index('topics', con_id.to_s, "#{topic1_id.to_s}-#{topic2_id.to_s}")
    end
  end

end
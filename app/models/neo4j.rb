class Neo4j

  class << self

    def neo
      @neo ||= ENV['NEO4J_URL'] ? Neography::Rest.new(ENV['NEO4J_URL']) : Neography::Rest.new
    end

    def parse_id(string)
      string.split('/').last.to_i
    end

    def find_or_create_category(name)
      topic = Topic.where("aliases.slug" => name.parameterize).first

      unless !topic || topic.is_category
        topic.is_category = true
        topic.save
      end

      unless topic
        topic = Topic.new
        topic.name = name
        topic.user_id = User.marc_id
        topic.is_category = true
        topic.save
      end

      topic.neo4j_node
    end

    def post_media_create(post_media)
      post_node = Neo4j.neo.get_node_index('post_media', 'uuid', post_media.id.to_s)

      post_media.neo4j_id = parse_id(post_node[0]['self'])
      post_media.save
    end

    def share_create(post, user)
      share = post.get_share(user.id)
      return unless share

      post_node = Neo4j.neo.get_node_index('post_media', 'uuid', post.id.to_s)
      user_node = Neo4j.neo.get_node_index('users', 'uuid', user.id.to_s)

      # add share relationship between user and post
      rel1 = Neo4j.neo.create_relationship('shared', user_node, post_node)
      Neo4j.neo.add_relationship_to_index('users', 'shared', "#{user.id.to_s}-#{post.id.to_s}", rel1)

      topic_node1 = nil
      topic_node2 = nil

      # increase affinity between mentioned topics and the sharer
      # increase the talk count between the user and mentioned topics
      share.topic_mentions.each_with_index do |t,i|
        if i == 0
          topic_node1 = Neo4j.neo.get_node_index('topics', 'uuid', t.id.to_s)
          Neo4j.update_affinity(user.id.to_s, t.id.to_s, user_node, topic_node1, 1)
          Neo4j.update_talk_count(user, t, 1, user_node, topic_node1)
        else
          topic_node2 = Neo4j.neo.get_node_index('topics', 'uuid', t.id.to_s)
          Neo4j.update_affinity(user.id.to_s, t.id.to_s, user_node, topic_node2, 1)
          Neo4j.update_talk_count(user, t, 1, user_node, topic_node2)
        end
      end

      # increase affinity between mentioned topics and each other
      if share.topic_mentions.length > 1
        topics = share.topic_mentions.to_a
        Neo4j.update_affinity(topics[0].id.to_s, topics[1].id.to_s, topic_node1, topic_node1, 1, true, nil)
      end
    end

    # update the talk relationship between a user and a topic
    def update_talk_count(user, topic, change, user_node=nil, topic_node=nil)
      talking = Neo4j.neo.get_relationship_index('talking', 'nodes', "#{user.id.to_s}-#{topic.id.to_s}")
      if talking
        payload = {}
        properties = Neo4j.neo.get_relationship_properties(talking)
        weight = properties && properties['weight'] ? properties['weight'] : 0
        if weight + change == 0
          Neo4j.neo.delete_relationship(talking)
          Neo4j.neo.remove_relationship_from_index('talking', talking)
        else
          payload['weight'] = weight+change
        end

        Neo4j.neo.set_relationship_properties(talking, payload) if payload.length > 0
      else
        user_node = Neo4j.neo.get_node_index('users', 'uuid', user.id.to_s) unless user_node
        topic_node = Neo4j.neo.get_node_index('topics', 'uuid', topic.id.to_s) unless topic_node

        talking = Neo4j.neo.create_relationship('talking', user_node, topic_node)
        Neo4j.neo.set_relationship_properties(talking, {
            'weight' => change
        })
        Neo4j.neo.add_relationship_to_index('talking', 'nodes', "#{user.id.to_s}-#{topic.id.to_s}", talking)
      end
    end

    def post_add_topics(topics)

    end

    def post_remove_topics(topics)

    end

    def post_create(post)
      creator_node = Neo4j.neo.get_node_index('users', 'uuid', post.user_id.to_s)

      post_node = Neo4j.neo.get_node_index('posts', 'uuid', post.id.to_s)

      post.neo4j_id = parse_id(post_node[0]['self'])
      post.save

      # connect it to it's overall category if present
      if post.category && !post.category.blank?
        category_node = find_or_create_category(post.category)
        Neo4j.neo.create_relationship('categorized in', post_node, category_node)
      end

      rel1 = Neo4j.neo.create_relationship('created', creator_node, post_node)
      Neo4j.neo.add_relationship_to_index('users', 'created', "#{post.user_id.to_s}-#{post.id.to_s}", rel1)

      post.user_mentions.each do |m|
        ## connect the post to it's mentioned users
        mention_node = Neo4j.neo.get_node_index('users', 'uuid', m.id.to_s)
        #rel2 = Neo4j.neo.create_relationship('mentions', post_node, mention_node)
        #Neo4j.neo.set_relationship_properties(rel2, {"type" => 'user'})
        #Neo4j.neo.add_relationship_to_index('posts', 'mentions', "#{post.id.to_s}-#{m.id.to_s}", rel2)

        # increase the creators affinity to these users
        Neo4j.update_affinity(post.user_id.to_s, m.id.to_s, creator_node, mention_node, 1, false, false)
      end

      topic_nodes = []
      post.topic_mentions.each do |m|
        mention_node = Neo4j.neo.get_node_index('topics', 'uuid', m.id.to_s)
        topic_nodes << {:node => mention_node, :node_id => m.id.to_s}
      end
      post.topic_mentions.each do |m|
        mention_node = topic_nodes.detect{|t| t[:node_id] == m.id.to_s}
        topic_nodes.delete_if{|t| t[:node_id] == m.id.to_s}
        topic_nodes ||= []
        post_add_topic_mention(post, m, post_node, creator_node, mention_node[:node], topic_nodes)
      end

      if post.post_media
        parent_node = Neo4j.neo.get_node_index('post_media', 'uuid', post.post_media_id.to_s)
        if parent_node
          media_rel = Neo4j.neo.create_relationship('media', post_node, parent_node)
          Neo4j.neo.set_relationship_properties(media_rel, {"created_at" => Time.now.utc.to_i})
          Neo4j.neo.add_relationship_to_index('posts', 'media', "#{post.id.to_s}-#{post.post_media_id.to_s}", media_rel)
        end
      end
    end

    # creates a follow relationship between two nodes
    def follow_create(node1_id, node2_id, node1_index, node2_index)
      node1 = self.neo.get_node_index(node1_index, 'uuid', node1_id)
      node2 = self.neo.get_node_index(node2_index, 'uuid', node2_id)

      unless node1
        target = Kernel.const_get(node1_index.singularize.capitalize).find(node1_id)
        node1 = target.neo4j_create
      end

      unless node2
        target = Kernel.const_get(node2_index.singularize.capitalize).find(node2_id)
        node2 = target.neo4j_create
      end

      if node1 && node2
        follow = self.neo.create_relationship('follow', node1, node2)
        self.neo.add_relationship_to_index('users', 'follow', "#{node1_id}-#{node2_id}", follow) if follow
        self.update_affinity(node1_id, node2_id, node1, node2, 10, false, nil, 'positive', false) if follow
      end
    end

    def follow_destroy(node1_id, node2_id, node1_index, node2_index)
      rel1 = Neo4j.neo.get_relationship_index('users', 'follow', "#{node1_id}-#{node2_id}")
      Neo4j.neo.delete_relationship(rel1)
      Neo4j.neo.remove_relationship_from_index('users', rel1)

      node1 = self.neo.get_node_index(node1_index, 'uuid', node1_id)
      node2 = self.neo.get_node_index(node2_index, 'uuid', node2_id)

      Neo4j.update_affinity(node1_id, node2_id, node1, node2, -10, false, nil, nil, false)
    end

    def post_add_topic_mention(post, topic, post_node=nil, creator_node=nil, mention_node=nil, topic_nodes=nil)
      # connect the post to it's mentioned topics
      #mention_node = Neo4j.neo.get_node_index('topics', 'uuid', topic.id.to_s) unless mention_node
      #creator_node = Neo4j.neo.get_node_index('users', 'uuid', post.user_id.to_s) unless creator_node
      #post_node = Neo4j.neo.get_node_index('posts', 'uuid', post.id.to_s) unless post_node

      #rel2 = Neo4j.neo.create_relationship('mentions', post_node, mention_node)
      #Neo4j.neo.set_relationship_properties(rel2, {"type" => 'topic'})
      #Neo4j.neo.add_relationship_to_index('posts', 'mentions', "#{post.id.to_s}-#{topic.id.to_s}", rel2)

      # increase the creators affinity to these topics
      unless post.user_id.to_s == User.limelight_user_id
        Neo4j.update_affinity(post.user_id.to_s, topic.id.to_s, creator_node, mention_node, 1, false, false)
      end

      unless topic_nodes
        topic_nodes = []
        post.topic_mentions.each do |m|
          if m.id != topic.id
            node = Neo4j.neo.get_node_index('topics', 'uuid', m.id.to_s)
            topic_nodes << {:node => node, :node_id => m.id.to_s}
          end
        end
      end

      # increase the mentioned topics affinity towards the other mentioned topics
      topic_nodes.each do |t|
        Neo4j.update_affinity(topic.id.to_s, t[:node_id], mention_node, t[:node], 1, true, nil)
      end
    end

    def post_remove_topic_mention(post, topic)

      mention_node = Neo4j.neo.get_node_index('topics', 'uuid', topic.id.to_s)
      return unless mention_node

      rel1 = Neo4j.neo.get_relationship_index('posts', 'mentions', "#{post.id.to_s}-#{topic.id.to_s}")
      return unless rel1

      Neo4j.neo.delete_relationship(rel1)
      Neo4j.neo.remove_relationship_from_index('posts', rel1)

      # decrease the creators affinity to these topics
      creator_node = Neo4j.neo.get_node_index('users', 'uuid', post.user_id.to_s)
      Neo4j.update_affinity(post.user_id.to_s, topic.id.to_s, creator_node, mention_node, -1, false, false)

      topic_nodes = []
      post.topic_mentions.each do |m|
        if m.id != topic.id
          node = Neo4j.neo.get_node_index('topics', 'uuid', m.id.to_s)
          topic_nodes << {:node => node, :node_id => m.id.to_s}
        end
      end

      # decrease the mentioned topics affinity towards the other mentioned topics
      topic_nodes.each do |t|
        Neo4j.update_affinity(topic.id.to_s, t[:node_id], mention_node, t[:node], -1, true, nil)
      end

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
        #unless node1 && node2
        #  node1 = self.neo.get_node_index(node1_index, 'uuid', node1_id)
        #  node2 = self.neo.get_node_index(node2_index, 'uuid', node2_id)
        #end

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
        WHERE has(r.connection_id)
        RETURN r,x
      "
      outgoing = Neo4j.neo.execute_query(query)

      query = "
        START n=node:topics(uuid = '#{topic_id.to_s}')
        MATCH (n)<-[r]-(x)
        WHERE has(r.connection_id)
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
        end
      end

      returnable = []
      organized.each do |type, data|
        returnable << {:name => type}.merge(data)
      end

      returnable
    end

    # get a topics pull from ids (aka the children)
    def pull_from_ids(topic_id, depth=20)
      query = "
        START n=node:topics(uuid = '#{topic_id}')
        MATCH n-[:pull*1..#{depth}]->x
        RETURN distinct x.uuid
      "
      ids = Neo4j.neo.execute_query(query)
      pull_from = []
      if ids
        ids['data'].each do |id|
          pull_from << Moped::BSON::ObjectId(id[0])
        end
      end
      pull_from
    end

    # get the topics that pull from the given topics (aka the parents)
    def pulled_from_ids(topic_id, depth=20)
      query = "
        START n=node:topics(uuid = '#{topic_id}')
        MATCH n<-[:pull*1..#{depth}]-x
        RETURN distinct x.uuid
      "
      ids = Neo4j.neo.execute_query(query)
      pull_from = []
      if ids
        ids['data'].each do |id|
          pull_from << Moped::BSON::ObjectId(id[0])
        end
      end
      pull_from
    end

    def user_topic_children(user_id, topic_id)
      query = "
        START n=node:topics(uuid = '#{topic_id}')
        MATCH n-[:pull]->x<-[:pull|talking*1..20]-y
        WHERE y.uuid = '#{user_id}'
        RETURN distinct x.uuid
      "
      ids = Neo4j.neo.execute_query(query)
      children_ids = []
      if ids
        ids['data'].each do |id|
          children_ids << Moped::BSON::ObjectId(id[0])
        end
      end
      children_ids
    end

    # user interests, used in the user sidebar
    #def user_interests(user_id, limit)
    #  interests = {:general => [], :specific => []}
    #
    #  # tally up what types are generally connected to topics this user likes
    #  #query = "
    #  #  START n=node:users(uuid = '#{user_id}')
    #  #  MATCH n-[:affinity]->topic-[r2:`Type Of`]->type
    #  #  WHERE topic.type = 'topic'
    #  #  RETURN type, COUNT(r2)
    #  #  ORDER BY count(r2) desc
    #  #  LIMIT 10
    #  #"
    #  #ids = self.neo.execute_query(query)
    #  #if ids
    #  #  ids['data'].each do |n|
    #  #    n[0]['data']['id'] = n[0]['data']['uuid']
    #  #    interests[:general] << {
    #  #            :data => n[0]['data'],
    #  #            :weight => n[1]
    #  #    }
    #  #  end
    #  #end
    #
    #  # tally up a users specific interests
    #  query = "
    #    START n=node:users(uuid = '#{user_id}')
    #    MATCH n-[r1:affinity]->topic
    #    WHERE topic.type = 'topic' and r1.weight! >= 50
    #    RETURN topic, r1.weight
    #    ORDER BY r1.weight desc
    #    LIMIT #{limit}
    #  "
    #  ids = self.neo.execute_query(query)
    #  if ids
    #    ids['data'].each do |n|
    #      n[0]['data']['id'] = n[0]['data']['uuid']
    #      interests[:specific] << {
    #              :data => n[0]['data'],
    #              :weight => n[1]
    #      }
    #    end
    #  end
    #
    #  interests
    #end

    # topic suggestions, used in the user sidebar and topic finder
    #def user_topic_suggestions(user_id, limit)
      #query = "
      #  START user=node:users(uuid = '#{user_id}')
      #  MATCH user-[r1:affinity]->topic<-[r2:affinity]-user2-[r3:affinity]->suggestion, user-[r4?:affinity]->suggestion, user-[r5?:follow]->suggestion
      #  WHERE topic.type = 'topic' and user2.type = 'user' and suggestion.type = 'topic' and r1.weight! >= 10 and has(r3.weight) and (r1.sentiment != 'negative') and (r4 IS NULL) and r5 IS NULL
      #  RETURN suggestion, SUM(r3.weight)
      #  ORDER BY SUM(r3.weight) desc
      #  LIMIT #{limit}
      #"
      #ids = self.neo.execute_query(query)
      #suggestions = []
      #if ids
      #  ids['data'].each do |n|
      #    n[0]['data']['id'] = n[0]['data']['uuid']
      #    suggestions << TopicSnippet.new(n[0]['data'])
      #  end
      #end
      #suggestions
    #end

    #def topic_similarity(topics)
    #  start_query = []
    #  match_query = []
    #  letter = "a"
    #  topics.each do |t|
    #    start_query << "#{letter}=node(#{t.neo4j_id})"
    #    match_query << "p#{letter}=shortestPath(:RELATED|TYPE_OF)"
    #    letter = letter.succ
    #  end
    #
    #  query = "
    #    START #{combos}}
    #    MATCH topic-[r:affinity]-related
    #    WHERE related.type = 'topic' and has(r.weight)
    #    RETURN related, SUM(r.weight)
    #    orDER BY SUM(r.weight) desc
    #    LIMIT #{limit}
    #  "
    #  ids = self.neo.execute_query(query)
    #end

    # related topic, used in the topic sidebar
    #def topic_related(topic_id, limit)
    #  query = "
    #    START topic=node:topics(uuid = '#{topic_id}')
    #    MATCH topic-[r:affinity]-related
    #    WHERE related.type = 'topic' and has(r.weight)
    #    RETURN related, SUM(r.weight)
    #    orDER BY SUM(r.weight) desc
    #    LIMIT #{limit}
    #  "
    #  ids = self.neo.execute_query(query)
    #  suggestions = []
    #  if ids
    #    ids['data'].each do |n|
    #      n[0]['data']['id'] = n[0]['data']['uuid']
    #      suggestions << n[0]['data']
    #    end
    #  end
    #  suggestions
    #end

    def get_sentiment(node1_id, node2_id)
      self.neo.get_relationship_index('sentiment', 'name', "#{node1_id}-#{node2_id}")
    end

    def get_connection(con_id, topic1_id, topic2_id)
      Neo4j.neo.get_relationship_index('topics', con_id.to_s, "#{topic1_id.to_s}-#{topic2_id.to_s}")
    end
  end

end
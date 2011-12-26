class TopicConnection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :reverse_name, :default => nil
  field :pull_from, :default => false
  field :reverse_pull_from, :default => false
  field :user_id

  belongs_to :user

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :user_id, :presence => true

  attr_accessible :name, :reverse_name, :pull_from, :reverse_pull_from

  # Return the topic slug instead of its ID
  def to_param
    self.name.to_url
  end

  class << self

    def add(connection, topic1, topic2, user_id)
      node1 = Neo4j.neo.get_node_index('topics', 'id', topic1.id.to_s)
      node2 = Neo4j.neo.get_node_index('topics', 'id', topic2.id.to_s)
      rel1 = Neo4j.neo.create_relationship(connection.name, node1, node2)
      Neo4j.neo.set_relationship_properties(rel1, {
              'connection_id' => connection.id.to_s,
              'reverse_name' => connection.reverse_name,
              'user_id' => user_id.to_s
      })
      Neo4j.neo.add_relationship_to_index('topic-relationships', 'key', "#{topic1.id.to_s}-#{connection.id.to_s}-#{topic2.id.to_s}", rel1)

      if connection.pull_from == true
        rel1 = Neo4j.neo.create_relationship('pull', node1, node2)
        Neo4j.neo.add_relationship_to_index('topic-pulls', 'key', "#{topic1.id.to_s}-pull-#{topic2.id.to_s}", rel1)
      end

      if connection.reverse_pull_from == true
        rel1 = Neo4j.neo.create_relationship('pull', node2, node1)
        Neo4j.neo.add_relationship_to_index('topic-pulls', 'key', "#{topic2.id.to_s}-pull-#{topic1.id.to_s}", rel1)
      end

      if connection.id.to_s == Topic.type_of_id && !topic1.primary_type
        topic1.primary_type = topic2.name
        Resque.enqueue(SmCreateTopic, topic1.id.to_s)
      end

      Neo4j.update_affinity(topic1.id.to_s, topic2.id.to_s, node1, node2, 10, true, true)
    end

    def remove(connection, topic1, topic2)
      rel1 = Neo4j.neo.get_relationship_index('topic-relationships', 'key', "#{topic1.id.to_s}-#{connection.id.to_s}-#{topic2.id.to_s}")
      Neo4j.neo.delete_relationship(rel1)
      Neo4j.neo.remove_relationship_from_index('topic-relationships', rel1)

      if connection.pull_from == true
        rel1 = Neo4j.neo.get_relationship_index('topic-pulls', 'key', "#{topic1.id.to_s}-pull-#{topic2.id.to_s}")
        Neo4j.neo.delete_relationship(rel1)
        Neo4j.neo.remove_relationship_from_index('topic-pulls', rel1)
      end

      if connection.reverse_pull_from == true
        rel1 = Neo4j.neo.get_relationship_index('topic-pulls', 'key', "#{topic2.id.to_s}-pull-#{topic1.id.to_s}")
        Neo4j.neo.delete_relationship(rel1)
        Neo4j.neo.remove_relationship_from_index('topic-pulls', rel1)
      end

      Neo4j.update_affinity(topic1.id.to_s, topic2.id.to_s, nil, nil, -10, true, false)
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
          organized[c[0]['data']['connection_id']] ||= {'relationship' => c[0]['data'], 'type' => type, 'connections' => []}
          organized[c[0]['data']['connection_id']]['connections'] << c[1]['data']
        end
      end

      if incoming
        incoming['data'].each do |c|
          type = c[0]['data']['reverse_name'].blank? ? c[0]['type'] : c[0]['data']['reverse_name']
          organized[c[0]['data']['connection_id']] ||= {'relationship' => c[0]['data'], 'type' => type, 'connections' => []}
          organized[c[0]['data']['connection_id']]['connections'] << c[1]['data']
        end
      end

      organized
    end

    def pull_from_ids(topic_id)
      query = "
        START n=node:topics(id = '#{topic_id}')
        MATCH n-[:pull*]->x
        RETURN distinct x.id
      "
      ids = Neo4j.neo.execute_query(query)
      pull_from = []
      ids['data'].each do |id|
        pull_from << BSON::ObjectId(id[0])
      end
      pull_from
    end
  end
end
class TopicConnection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :reverse_name, :default => nil
  field :inline
  field :pull_from, :default => false, :type => Boolean
  field :reverse_pull_from, :default => false, :type => Boolean
  field :user_id

  belongs_to :user

  validates :name, :presence => true, :uniqueness => { :case_sensitive => false }
  validates :user_id, :presence => true

  attr_accessible :name, :reverse_name, :pull_from, :reverse_pull_from, :inline

  # Return the topic slug instead of its ID
  def to_param
    self.name.to_url
  end

  class << self

    # pulla is a hash of format { :pull => Boolean, :reverse_pull => Boolean }
    #TODO: delete suggestions that match topics and connection
    #TODO: improve error detection - return false and don't save topics if no connection was created?
    def add(connection, topic1, topic2, user_id, pulla=nil)
      rel1 = Neo4j.neo.get_relationship_index('topics', connection.id.to_s, "#{topic1.id.to_s}-#{topic2.id.to_s}")
      unless rel1
        node1 = Neo4j.neo.get_node_index('topics', 'uuid', topic1.id.to_s)
        node2 = Neo4j.neo.get_node_index('topics', 'uuid', topic2.id.to_s)
        rel1 = Neo4j.neo.create_relationship(connection.name, node1, node2)
        Neo4j.neo.set_relationship_properties(rel1, {
                'connection_id' => connection.id.to_s,
                'reverse_name' => connection.reverse_name,
                'inline' => connection.inline,
                'user_id' => user_id.to_s
        })
        Neo4j.neo.add_relationship_to_index('topics', connection.id.to_s, "#{topic1.id.to_s}-#{topic2.id.to_s}", rel1)

        if (pulla == nil && connection.pull_from == true) || (pulla != nil && pulla[:pull])
          rel1 = Neo4j.neo.create_relationship('pull', node1, node2)
          Neo4j.neo.add_relationship_to_index('topics', 'pull', "#{topic1.id.to_s}-#{topic2.id.to_s}", rel1)
        end

        if (pulla == nil && connection.reverse_pull_from == true) || (pulla != nil && pulla[:reverse_pull])
          rel1 = Neo4j.neo.create_relationship('pull', node2, node1)
          Neo4j.neo.add_relationship_to_index('topics', 'pull', "#{topic2.id.to_s}-#{topic1.id.to_s}", rel1)
        end

        if connection.id.to_s == Topic.type_of_id
          topic1.update_health('type')
          if !topic1.primary_type
            topic1.primary_type = topic2.name
            Resque.enqueue(SmCreateTopic, topic1.id.to_s)
          end
        else
          topic1.update_health('connection')
          topic2.update_health('connection')
        end

        topic1.save
        topic2.save
        TopicConSug.destroy_all(conditions: { con_id: connection.id, topic1_id: topic1.id, topic2_id: topic2.id })
        Neo4j.update_affinity(topic1.id.to_s, topic2.id.to_s, node1, node2, 10, true, true)
        true
      else
        false
      end
    end

    def remove(connection, topic1, topic2)
      rel1 = Neo4j.neo.get_relationship_index('topics', connection.id.to_s, "#{topic1.id.to_s}-#{topic2.id.to_s}")
      Neo4j.neo.delete_relationship(rel1)
      Neo4j.neo.remove_relationship_from_index('topics', rel1)

      if connection.pull_from == true
        rel1 = Neo4j.neo.get_relationship_index('topics', 'pull', "#{topic1.id.to_s}-#{topic2.id.to_s}")
        Neo4j.neo.delete_relationship(rel1)
        Neo4j.neo.remove_relationship_from_index('topics', rel1)
      end

      if connection.reverse_pull_from == true
        rel1 = Neo4j.neo.get_relationship_index('topics', 'pull', "#{topic2.id.to_s}-#{topic1.id.to_s}")
        Neo4j.neo.delete_relationship(rel1)
        Neo4j.neo.remove_relationship_from_index('topics', rel1)
      end

      if connection.id.to_s == Topic.type_of_id
        query = "
          START topic=node:topics(id = '#{topic1.id.to_s}')
          MATCH topic-[r1:`Type Of`]->topic2
          RETURN r1,topic2
        "
        types = Neo4j.neo.execute_query(query)
        if types['data'].length > 0 && topic1.primary_type == topic2.name
          topic1.primary_type = types['data'][0][1]['data']['name']
        elsif types['data'].length == 0
          topic1.primary_type = nil
        end
        topic1.save
        Resque.enqueue(SmCreateTopic, topic1.id.to_s)
      end

      Neo4j.update_affinity(topic1.id.to_s, topic2.id.to_s, nil, nil, -10, true, false)
    end
  end
end
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

  attr_accessible :name, :reverse_name, :pull, :reverse_pull

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
              'id' => connection.id.to_s,
              'reverse_name' => connection.reverse_name,
              'pull_from' => connection.pull_from,
              'reverse_pull_from' => connection.reverse_pull_from,
              'user_id' => user_id.to_s})
      Neo4j.neo.add_relationship_to_index('connections', 'id', connection.id.to_s, rel1)
    end

    #def add_connection(connection, con_topic, user_id, primary=false)
    #  if !connection.opposite.blank? && opposite = TopicConnection.find(connection.opposite)
    #    con_topic.add_connection_helper(opposite, self, user_id, primary)
    #  end
    #  self.add_connection_helper(connection, con_topic, user_id, primary)
    #end
    #
    #def add_connection_helper(connection, con_topic, user_id, primary)
    #  if self.has_connection?(connection.id, con_topic.id)
    #    false
    #  else
    #    snippet = TopicConnectionSnippet.new()
    #    snippet.id = connection.id
    #    snippet.name = connection.name
    #    snippet.pull_from = connection.pull_from
    #    snippet.topic_id = con_topic.id
    #    snippet.topic_name = con_topic.name
    #    snippet.topic_slug = con_topic.slug
    #    snippet.user_id = user_id
    #    if connection.id.to_s == Topic.type_of_id && (primary || get_primary_types.empty?)
    #      snippet.primary = true
    #      update_health("type")
    #      self.v += 1
    #    end
    #    if connection.id.to_s != Topic.type_of_id
    #      update_health("connection")
    #    end
    #    self.topic_connection_snippets << snippet
    #
    #    node1 = Neo4j.neo.get_node_index('topics', 'id', id.to_s)
    #    node2 = Neo4j.neo.get_node_index('topics', 'id', con_topic.id.to_s)
    #    rel1 = Neo4j.neo.create_relationship(connection.name, node1, node2)
    #    Neo4j.neo.set_relationship_properties(rel1, {'primary' => snippet.primary, 'pull' => snippet.pull_from, 'user_id' => user_id.to_s})
    #
    #    true
    #  end
    #end
  end
end
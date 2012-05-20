class TestJob

  @queue = :fast

  def self.perform()
    type_connection = TopicConnection.find(Topic.type_of_id)
    topics = Topic.all
    topics.each do |t|
      node = Neo4j.neo.get_node_index('topics', 'uuid', t.id.to_s)

      unless node
        t.neo4j_create
      else
        t.neo4j_id = node[0]['self'].split('/').last
        t.save
      end

      if t.primary_type_id
        type = Topic.find(t.primary_type_id)
        saved = true
        unless type
          type = Topic.new
          type.name = t.primary_type
          type.user_id = User.marc_id
          saved = type.save
        end
        if saved
          TopicConnection.add(type_connection, t, type, User.marc_id, {:pull => false, :reverse_pull => true})
        end
      end
    end

    users = User.all
    users.each do |u|
      node = Neo4j.neo.get_node_index('users', 'uuid', u.id.to_s)

      unless node
        u.neo4j_create
      else
        u.neo4j_id = node[0]['self'].split('/').last
        u.save
      end
    end

    posts = Post.all
    posts.each do |p|
      node = Neo4j.neo.get_node_index('posts', 'uuid', p.id.to_s)

      unless node
        begin
          p.neo4j_create
        rescue => e
          p.delete
        end
      else
        p.neo4j_id = node[0]['self'].split('/').last

        begin
          p.save
        rescue => e
          p.delete
        end

      end
    end
  end
end
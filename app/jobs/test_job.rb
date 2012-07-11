class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    Topic.each do |t|
      t.neo4j_id = t.neo4j_id.to_i
      t.save
    end
    PostMedia.each do |t|
      t.neo4j_id = t.neo4j_id.to_i
      t.save
    end
    Post.each do |t|
      t.neo4j_id = t.neo4j_id.to_i
      t.save
    end
    User.each do |t|
      t.neo4j_id = t.neo4j_id.to_i
      t.save
    end

    Topic.each do |t|
    #Topic.where(:name => 'Instagram').each do |t|
      node = Neo4j.neo.get_node(t.neo4j_id)
      relationships = Neo4j.neo.get_node_relationships(node, "all")
      if relationships
        relationships.each do |r|
          target = Topic.where(:neo4j_id => Neo4j.parse_id(r['end']).to_i).first
          target = PostMedia.where(:neo4j_id => Neo4j.parse_id(r['end']).to_i).first unless target
          target = Post.where(:neo4j_id => Neo4j.parse_id(r['end']).to_i).first unless target
          target = User.where(:neo4j_id => Neo4j.parse_id(r['end']).to_i).first unless target
          unless target
            puts Neo4j.parse_id(r['end'])
            node = Neo4j.neo.get_node(Neo4j.parse_id(r['end']).to_i)
            Neo4j.neo.delete_node!(node) if node
          end
        end
      end
    end

  end
end
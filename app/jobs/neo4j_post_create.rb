require 'json'

class Neo4jPostCreate

  @queue = :neo4j

  def self.perform(post_id)
    post = CoreObject.find(post_id)
    if post

      creator_node = Neo4j.neo.get_node_index('users', 'id', post.user_id.to_s)

      post_node = Neo4j.neo.get_node_index('posts', 'id', post.id.to_s)
      unless post_node
        post_node = Neo4j.neo.create_node(
                'id' => post.id.to_s,
                'type' => 'post',
                'subtype' => post.class.name,
                'public_id' => post.public_id
        )
        Neo4j.neo.add_node_to_index('posts', 'id', post.id.to_s, post_node)
      end

      rel1 = Neo4j.neo.create_relationship('created', creator_node, post_node)
      Neo4j.neo.add_relationship_to_index('users', 'created', "#{post.user_id.to_s}-#{post.id.to_s}", rel1)

      post.user_mentions.each do |m|
        # connect the post to it's mentioned users
        mention_node = Neo4j.neo.get_node_index('users', 'id', m.id.to_s)
        rel2 = Neo4j.neo.create_relationship('mentions', post_node, mention_node)
        Neo4j.neo.set_relationship_properties(rel2, {"type" => 'user'})
        Neo4j.neo.add_relationship_to_index('posts', 'mentions', "#{post.id.to_s}-#{m.id.to_s}", rel2)

        # increase the creators affinity to these users
        Neo4j.update_affinity(post.user_id.to_s, m.id.to_s, creator_node, mention_node, 10, false, false)
      end

      topics = []
      post.topic_mentions.each do |m|
        # connect the post to it's mentioned topics
        mention_node = Neo4j.neo.get_node_index('topics', 'id', m.id.to_s)
        rel2 = Neo4j.neo.create_relationship('mentions', post_node, mention_node)
        Neo4j.neo.set_relationship_properties(rel2, {"type" => 'topic'})
        Neo4j.neo.add_relationship_to_index('posts', 'mentions', "#{post.id.to_s}-#{m.id.to_s}", rel2)

        # increase the creators affinity to these topics
        Neo4j.update_affinity(post.user_id.to_s, m.id.to_s, creator_node, mention_node, 10, false, false)

        topics << {:node => mention_node, :node_id => m.id.to_s}
      end

      # increase the mentioned topics affinities towards each other
      topics.combination(2).to_a.each do |t|
        Neo4j.update_affinity(t[0][:node_id], t[1][:node_id], t[0][:node], t[1][:node], 2, true, nil)
      end
    end
  end

end
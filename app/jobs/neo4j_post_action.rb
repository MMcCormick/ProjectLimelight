#require 'json'
#
## called for post actions (vote, like, favorite, etc)
#class Neo4jPostAction
#
#  @queue = :neo4j
#
#  def self.perform(user_id, post_id, change)
#    node1 = Neo4j.neo.get_node_index('users', 'uuid', user_id)
#    post = CoreObject.find(post_id)
#
#    if node1 && post
#      # increase affinity to the post creator
#      node2 = Neo4j.neo.get_node_index('users', 'uuid', post.user_id.to_s)
#      Neo4j.update_affinity(user_id, post.user_id.to_s, node1, node2, change*2, false, nil) if node2
#
#      # increase affinity to mentioned users
#      post.user_mentions.each do |m|
#        node2 = Neo4j.neo.get_node_index('users', 'uuid', m.id.to_s)
#        Neo4j.update_affinity(user_id, m.id.to_s, node1, node2, change, false, nil) if node2
#      end
#
#      # increase affinity to mentioned topics
#      post.topic_mentions.each do |m|
#        node2 = Neo4j.neo.get_node_index('topics', 'uuid', m.id.to_s)
#        Neo4j.update_affinity(user_id, m.id.to_s, node1, node2, change, false, nil) if node2
#      end
#    end
#  end
#
#end
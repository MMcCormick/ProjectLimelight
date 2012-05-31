class TestJob

  @queue = :fast

  def self.perform()
    #Post.all.destroy
    #FeedUserItem.all.delete
    #FeedTopicItem.all.delete
    #FeedContributeItem.all.delete
    #FeedLikeItem.all.delete
    #Comment.all.delete
    #PopularityAction.all.delete
    #
    #User.update_all(:score => 0.0, :likes_count => 0, :unread_notification_count => 0, :clout => 1, )
    #
    #@destroyed = 0
    #@updated = 0
    #topics = Topic.all
    #topics.each do |t|
    #  primary_for = Topic.where(:primary_type_id => t.id)
    #  if primary_for.length == 0 && t.followers_count == 0 && !t.fb_page_id && !t.is_category && !t.primary_type_id
    #    t.destroy!
    #    @destroyed += 1
    #  else
    #    t.score = 0.0
    #    t.talking_ids = []
    #    t.response_count = 0
    #    t.influencers = {}
    #    t.save
    #    @updated += 1
    #  end
    #end
    #
    ##time_id = BSON::ObjectId.from_time(Chronic.parse('7 days ago'))
    ##topics = Topic.where(:_id.gt => time_id).to_a
    ##topics.each do |t|
    ##  t.destroy!
    ##end
    #
    #topics = Topic.all
    #topics.each do |t|
    #  if t.primary_type_id
    #    primary = Topic.find(t.primary_type_id)
    #    if primary
    #      primary.is_topic_type = true
    #      primary.save
    #    else
    #      t.unset_primary_type
    #      t.save
    #    end
    #  end
    #
    #  t.generate_slug
    #
    #  if t.freebase_guid
    #    t.freebase_guid = t.freebase_guid.split('.').last
    #    t.freebase_guid = "#" + t.freebase_guid unless t.freebase_guid[0] == '#'
    #  end
    #
    #  t.save
    #
    #  t.freebase_repopulate(true, true, true)
    #end
    #
    #crawlers = CrawlerSource.all
    #crawlers.each do |c|
    #  c.last_modified = nil
    #  c.last_crawled = nil
    #  c.etag = nil
    #  c.posts_added = 0
    #  c.save
    #end

    Topic.all.update(:followers_count => 0)
    User.all.update(:followers_count => 0)

    users = User.all
    users.each do |u|
      node = Neo4j.neo.get_node_index('users', 'uuid', u.id.to_s)
      if node
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'like')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'affinity')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'follow')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'mentions')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'created')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end
        nodes = Neo4j.neo.get_node_relationships(node, 'all', 'talked')
        if nodes
          nodes.each do |n|
            Neo4j.neo.delete_relationship(n)
          end
        end

        u.following_users.each do |fu|
          fun = User.find(fu)
          if fun
            fun.followers_count += 1
            fun.save
            Neo4j.follow_create(u.id.to_s, fun.id.to_s, 'users', 'users')
          else
            u.following_users.delete(fu)
          end
          u.following_users_count = u.following_users.length
        end

        u.following_topics.each do |fu|
          fut = Topic.find(fu)

          if fut
            fut.followers_count += 1
            fut.save
            Neo4j.follow_create(u.id.to_s, fut.id.to_s, 'users', 'topics')
          else
            u.following_topics.delete(fu)
          end
          u.following_topics_count = u.following_topics.length
        end

        u.save

      end
    end
  end
end
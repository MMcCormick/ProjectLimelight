class TestJob

  @queue = :fast

  def self.perform()
    #Post.where(:_id.lte => BSON::ObjectId.from_time(Chronic.parse('3 days ago'))).delete

    ## rebuild user neo4
    #User.all.each do |u|
    #  u.neo4j_create
    #end
    ## rebuild topic neo4
    #Topic.all.each do |t|
    #  t.neo4j_create
    #end
    # rebuild neo4j following
    User.each do |u|
      u.following_users_count = 0
      u.following_topics_count = 0

      u.following_users.each do |u2_id|
        u2 = User.find(u2_id)
        if u2
          u.following_users_count += 1
          #Resque.enqueue(Neo4jFollowCreate, u.id.to_s, u2.id.to_s, 'users', 'users')
        else
          u.following_users.delete(u2_id)
        end
      end
      u.following_topics.each do |t_id|
        t = Topic.find(t_id)
        if t
          u.following_topics_count += 1
          Resque.enqueue(Neo4jFollowCreate, u.id.to_s, t.id.to_s, 'users', 'topics')
        else
          u.following_topics.delete(t_id)
        end
      end
      u.save
    end
    ## rebuild topic connections
    #type_of = TopicConnection.find(Topic.type_of_id)
    #ActionConnection.all.delete
    #Topic.all.each do |t|
    #  if t.primary_type_id
    #    t2 = Topic.find(t.primary_type_id)
    #    if t2
    #      TopicConnection.add(type_of, t, t2, User.marc_id, {:pull => false, :reverse_pull => true})
    #    end
    #  end
    #end
    #
    #Post.collection.find({"_type" => {"$exists" => true}}).update_all({"$unset" => {"_type" => 1}})
    #
    #FeedTopicItem.delete_all
    #FeedContributeItem.delete_all
    #FeedUserItem.delete_all
    #
    ## connect post to post media
    #Post.all.asc(:_id).each do |p|
    #  if p['title'] && !p['title'].blank? && ['Link','Picture','Video'].include?(p['root_type'])
    #    new_media = Kernel.const_get(p['root_type']).new
    #    new_media.user_id = p.user_id
    #    new_media.source_name = p.sources.first.name
    #    new_media.source_url = p.sources.first.url
    #    new_media.source_video_id = p.sources.first.video_id
    #    new_media.title = p.title
    #    new_media.description = p.description
    #    if p.remote_image_url
    #      new_media.remote_image_url = p.remote_image_url
    #    end
    #
    #    new_media.save
    #
    #    p.post_media_id = new_media.id
    #    if p.topic_mention_ids.length > 2
    #      p.topic_mention_ids = p.topic_mention_ids.first(2)
    #    end
    #    p.save
    #  end
    #end
    #
    ## rebuild post neo4. happens after media created because posts need to be connected to media
    #Post.all.each do |p|
    #  p.neo4j_create
    #end
    #
    ## rebuild likes in neo4j
    #User.all.each do |u|
    #  posts = Post.where(:like_ids => u.id)
    #  posts.each do |p|
    #    Resque.enqueue(Neo4jPostLike, u.id.to_s, p.id.to_s)
    #  end
    #end
    #
    ## push all posts to feed
    #Post.all.asc(:_id).each do |p|
    #  if p.response_to_id
    #    post = Post.find(p.response_to_id)
    #    if post
    #      p.post_media_id = post.post_media_id
    #      p.save
    #    end
    #  end
    #  Resque.enqueue(PushPostToFeeds, p.id.to_s)
    #end
    #
    ## fix like items
    #FeedLikeItem.all.each do |p|
    #  if p.root_type != 'Post' && p.root_type != 'Talk'
    #    post = Post.find(p.root_id)
    #    if post && post.post_media_id
    #      p.root_id = post.post_media_id
    #      p.responses << post.id
    #      p.save
    #    else
    #      p.delete
    #    end
    #  else
    #    post = Post.find(p.root_id)
    #    if post
    #      p.root_type = 'Post'
    #      p.save
    #    else
    #      p.delete
    #    end
    #  end
    #end
    #
    ## recalc user counts
    #User.all.each do |u|
    #  u.topic_likes_recalculate
    #  u.topic_activity_recalculate
    #  u.save
    #end

  end
end
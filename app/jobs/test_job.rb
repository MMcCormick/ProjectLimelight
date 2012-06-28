class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    Post.all.each do |p|
      comments = Comment.where(:post_id => p.id)
      p.comment_count = comments.length
      p.save
    end

    Notification.each do |n|
      unless n.triggered_by
        n.delete
      end
    end

    #PostMedia.all.each do |p|
    #  if p.remote_image_url && !p.remote_image_url.blank? && p.active_image_version == 0
    #    Resque.enqueue(ProcessImages, p.id.to_s, p.class.name, 0, p.remote_image_url)
    #  end
    #end

    #PostMedia.all.each do |p|
    #  if p.remote_image_url && !p.remote_image_url.blank?
    #    p.active_image_version = 0
    #    p.image_versions = 0
    #    p.save
    #    Resque.enqueue(ProcessImages, p.id.to_s, p.class.name)
    #  end
    #end

    #u = User.find('4feb2ec918b8f10300000014')
    #u.neo4j_create
    #u.following_users_count = 0
    #u.following_topics_count = 0
    #
    #u.following_users.each do |u2_id|
    #  u2 = User.find(u2_id)
    #  if u2
    #    u.following_users_count += 1
    #    ActionFollow.create(:action => 'create', :from_id => u.id, :to_id => u2.id, :to_type => 'User')
    #    Resque.enqueue(Neo4jFollowCreate, u.id.to_s, u2.id.to_s, 'users', 'users')
    #  else
    #    u.following_users.delete(u2_id)
    #  end
    #end
    #u.following_topics.each do |t_id|
    #  t = Topic.find(t_id)
    #  if t
    #    u.following_topics_count += 1
    #    ActionFollow.create(:action => 'create', :from_id => u.id, :to_id => t.id, :to_type => 'Topic')
    #    Resque.enqueue(Neo4jFollowCreate, u.id.to_s, t.id.to_s, 'users', 'topics')
    #  else
    #    u.following_topics.delete(t_id)
    #  end
    #end
    #u.save
    #
    #u.topic_likes_recalculate
    #u.topic_activity_recalculate
    #u.save

    #FeedTopicItem.delete_all
    #FeedContributeItem.delete_all
    #FeedUserItem.delete_all
    #FeedLikeItem.delete_all
    #User.update_all(:score => 0)
    #
    ## delete stupid posts
    #Post.each do |p|
    #  comments = Comment.where(:talk_id => p.id)
    #  responses = Post.where(:response_to_id => p.id)
    #  if comments.length.to_i == 0 && p.like_ids.length == 0 && responses.length == 0 && p.user_id.to_s == User.limelight_user_id
    #    Post.collection.find(:_id => p.id).remove()
    #  else
    #    p.comment_count = 0
    #    comments.each do |c|
    #      c.post_id = c.talk_id
    #      c.save
    #      p.comment_count += 1
    #    end
    #    p.save
    #  end
    #end
    #
    ## delete stupid topics
    #Topic.all.each do |t|
    #  posts = Post.where(:topic_mention_ids => t.id)
    #  if posts.length == 0 && t.followers_count == 0 && !t.is_topic_type && !t.is_category && t.category_ids.length == 0
    #    Topic.collection.find(:_id => t.id).remove()
    #  end
    #end
    #
    #puts 'rebuilding neo4j users'
    #User.all.each do |u|
    #  u.neo4j_create
    #end
    #
    #puts 'rebuilding neo4j topics'
    ## rebuild topic neo4
    #Topic.all.each do |t|
    #  t.neo4j_create
    #end
    #
    #puts 'rebuilding user connections'
    #User.each do |u|
    #  u.following_users_count = 0
    #  u.following_topics_count = 0
    #
    #  u.following_users.each do |u2_id|
    #    u2 = User.find(u2_id)
    #    if u2
    #      u.following_users_count += 1
    #      ActionFollow.create(:action => 'create', :from_id => u.id, :to_id => u2.id, :to_type => 'User')
    #      Resque.enqueue(Neo4jFollowCreate, u.id.to_s, u2.id.to_s, 'users', 'users')
    #    else
    #      u.following_users.delete(u2_id)
    #    end
    #  end
    #  u.following_topics.each do |t_id|
    #    t = Topic.find(t_id)
    #    if t
    #      u.following_topics_count += 1
    #      ActionFollow.create(:action => 'create', :from_id => u.id, :to_id => t.id, :to_type => 'Topic')
    #      Resque.enqueue(Neo4jFollowCreate, u.id.to_s, t.id.to_s, 'users', 'topics')
    #    else
    #      u.following_topics.delete(t_id)
    #    end
    #  end
    #  u.save
    #end
    #
    #puts 'rebuilding topic connections'
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

    #Post.collection.find({"_type" => {"$exists" => true}}).update_all({"$unset" => {"_type" => 1}})
    #
    #puts 'connecting posts to post media'
    #Post.all.asc(:_id).each do |p|
    #
    #  if ['Link','Picture','Video'].include?(p['root_type'])
    #
    #    if p['root_id'] == p.id
    #      new_media = Kernel.const_get(p['root_type']).new
    #      new_media.user_id = p.user_id
    #      new_media.source_name = p.sources.first.name
    #      new_media.source_url = p.sources.first.url
    #      new_media.source_video_id = p.sources.first.video_id
    #      new_media.title = p.title
    #      new_media.description = p.description
    #      if p.remote_image_url
    #        new_media.remote_image_url = p.remote_image_url
    #      end
    #
    #      new_media.save
    #
    #      p.post_media_id = new_media.id
    #      responses = Post.where(:response_to_id => p.id)
    #      responses.each do |r|
    #        r.post_media_id = new_media.id
    #        r.save
    #      end
    #
    #      if p.user_id != User.limelight_user_id
    #        Post.collection.find(:_id => p.id).remove()
    #        next
    #      end
    #    end
    #
    #    if p.topic_mention_ids.length > 2
    #      p.topic_mention_ids = p.topic_mention_ids.first(2)
    #    end
    #    p.save
    #  end
    #
    #  ActionPost.create(:action => 'create', :from_id => p.user_id, :to_id => p.id, :to_type => 'Post')
    #  p.add_pop_action(:new, :a, p.user)
    #end

    ## reassign media
    #Post.all.each do |p|
    #  if p.response_to_id && !p.post_media_id
    #    post = Post.find(p.response_to_id)
    #    if post
    #      p.post_media_id = post.post_media_id
    #      p.save
    #    end
    #  end
    #end
    #
    ## delete useless ones again
    #Post.all.each do |p|
    #  if ['Link','Picture','Video'].include?(p['root_type']) && p['root_id'] == p.id && !p.content.blank?
    #    Post.collection.find(:_id => p.id).remove()
    #  end
    #end

    #puts 'rebuilding neo4j posts'
    #Post.all.each do |p|
    #  p.neo4j_create
    #end
    #
    #puts 'rebuilding neo4j likes'
    #User.all.each do |u|
    #  posts = Post.where(:like_ids => u.id)
    #  posts.each do |p|
    #    p.add_pop_action(:lk, :a, u)
    #    Resque.enqueue(Neo4jPostLike, u.id.to_s, p.id.to_s)
    #    Resque.enqueue(PushLike, p.id.to_s, u.id.to_s)
    #  end
    #end
    #
    #puts 'push posts to feeds'
    #Post.all.asc(:_id).each do |p|
    #  Resque.enqueue(PushPostToFeeds, p.id.to_s)
    #end
    #

    #Post.all.each do |p|
    #  dup = Post.where(:content => p.content)
    #  dup.each do |d|
    #    unless d.id == p.id
    #      d.destroy
    #      Post.collection.find(:_id => d.id).remove()
    #    end
    #  end
    #end
    #
    #Post.all.each do |p|
    #  if p.response_to_id && p.post_media_id
    #    media = PostMedia.find(p.post_media_id)
    #    if media && !media.remote_image_url || media.remote_image_url.blank?
    #      url = URI.parse("http://img.p-li.me/#{media.class.name.downcase.pluralize}/#{p.response_to_id}/1/original.png")
    #      req = Net::HTTP.new(url.host, url.port)
    #      res = req.request_head(url.path)
    #      if res.code == "200"
    #        media.remote_image_url = "http://img.p-li.me/#{media.class.name.downcase.pluralize}/#{p.response_to_id}/1/original.png"
    #        media.active_image_version = 0
    #        media.image_versions = 0
    #        media.save
    #        media.process_images
    #      end
    #    end
    #  end
    #end

    #puts 'recalc user counts'
    #User.all.each do |u|
    #  u.topic_likes_recalculate
    #  u.topic_activity_recalculate
    #  u.save
    #end

  end
end
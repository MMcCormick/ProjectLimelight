class TestJob

  @queue = :fast

  def self.perform()
    Post.where(:_id.lte => BSON::ObjectId.from_time(Chronic.parse('5 days ago'))).delete

    Post.collection.find({"_type" => {"$exists" => true}}).update_all({"$unset" => {"_type" => 1}})

    FeedTopicItem.delete_all
    FeedContributeItem.delete_all
    FeedUserItem.delete_all

    Post.all.asc(:_id).each do |p|
      if p['title'] && !p['title'].blank? && ['Link','Picture','Video'].include?(p['root_type'])
        new_media = Kernel.const_get(p['root_type']).new
        new_media.user_id = p.user_id
        new_media.source_name = p.sources.first.name
        new_media.source_url = p.sources.first.url
        new_media.source_video_id = p.sources.first.video_id
        new_media.title = p.title
        new_media.description = p.description
        if p.remote_image_url
          new_media.remote_image_url = p.remote_image_url
        end

        #Post.where(:_id => p.id).delete
        #node = Neo4j.neo.get_node_index('posts', 'uuid', p.id.to_s)
        #Neo4j.neo.delete_node!(node) if node

        new_media.save

        p.post_media_id = new_media.id
        if p.topic_mention_ids.length > 2
          p.topic_mention_ids = p.topic_mention_ids.first(2)
        end
        p.save
      end
    end

    Post.all.asc(:_id).each do |p|
      if p.response_to_id
        post = Post.find(p.response_to_id)
        if post
          p.post_media_id = post.post_media_id
          p.save
        end
      end
      Resque.enqueue(PushPostToFeeds, p.id.to_s)
    end

    FeedLikeItem.all.each do |p|
      if p.root_type != 'Post' && p.root_type != 'Talk'
        post = Post.find(p.root_id)
        if post && post.post_media_id
          p.root_id = post.post_media_id
          p.responses << post.id
          p.save
        else
          p.delete
        end
      else
        post = Post.find(p.root_id)
        if post
          p.root_type = 'Post'
          p.save
        else
          p.delete
        end
      end
    end

    User.all.each do |u|
      u.topic_likes_recalculate
      u.topic_activity_recalculate
      u.save
    end

  end
end
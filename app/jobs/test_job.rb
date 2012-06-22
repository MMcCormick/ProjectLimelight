class TestJob

  @queue = :fast

  def self.perform()
    FeedTopicItem.delete_all
    FeedContributeItem.delete_all
    FeedUserItem.delete_all

    Post.all.asc(:_id).each do |p|
      if p['title'] && !p['title'].blank? && p['_type'] != 'Talk' && p['root_type'] != 'Talk' && p['tmp_type'] != 'Talk'
        new_media = Kernel.const_get(p['_type']).new
        new_media.id = p.id
        new_media.user_id = p.user_id
        new_media.source_name = p.sources.first.name
        new_media.source_url = p.sources.first.url
        new_media.source_video_id = p.sources.first.video_id
        new_media.title = p.title
        new_media.content = p.content
        new_media.description = p.description

        if new_media.user_id.to_s == User.limelight_user_id
          new_post = Post.new
          new_post.user_id = BSON::ObjectId(User.limelight_user_id)
          new_post.topic_mention_ids = p.topic_mention_ids.first(2)
          new_post.post_media_id = p.id
          new_post.save
        end

        Post.where(:_id => p.id).delete
        node = Neo4j.neo.get_node_index('posts', 'uuid', p.id.to_s)
        Neo4j.neo.delete_node!(node) if node

        new_media.save
      else
        if p.response_to_id
          p.post_media_id = p.response_to_id
          p.save
        end
        p.push_to_feeds
      end
    end
  end
end
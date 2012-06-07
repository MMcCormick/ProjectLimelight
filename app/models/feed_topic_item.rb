class FeedTopicItem
  include Mongoid::Document

  field :root_id
  field :root_type
  field :mentions
  field :last_response_time, :default => Time.now
  field :p, :default => 0

  index({ :root_id => -1 })
  index({ :mentions => 1, :last_response_time => -1 })
  index({ :mentions => 1, :p => -1 })

  def created_at
    id.generation_time
  end

  class << self

    def post_create(post)
      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      root_type = post.root_type == 'Topic' ? post.class.name : post.root_type

      item = FeedTopicItem.find_or_initialize_by(:root_id => root_id)
      item.last_response_time = Time.now
      item.root_type = root_type
      item.mentions = post.topic_mention_ids
      item.save
    end

    def push_post_through_topic(post, topic)
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      items = FeedTopicItem.where(:root_id => root_id)
      items.each do |item|
        unless item.mentions.detect{|i| i == topic.id}
          item.mentions << topic.id
        end
        item.save
      end
    end

    def unpush_post_through_topic(post, topic)
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      items = FeedTopicItem.where(:root_id => root_id)
      items.each do |item|
        item.mentions.delete(topic.id)
        if item.mentions.length == 0
          item.delete
        else
          item.save
        end
      end
    end

    def post_destroy(post)
      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id

      FeedTopicItem.where(:root_id => post.id).delete if root_id == post.id
    end

    def topic_destroy(topic)
      items = FeedTopicItem.where(:mentions => topic.id)
      items.each do |item|
        item.mentions.delete(topic.id)
        if item.mentions.length == 0
          item.delete
        else
          item.save
        end
      end
    end
  end
end
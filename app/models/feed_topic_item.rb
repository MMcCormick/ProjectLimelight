class FeedTopicItem
  include Mongoid::Document

  field :root_id
  field :root_type
  field :mentions
  field :p, :default => 0

  index [[ :root_id, Mongo::DESCENDING ]]
  index(
    [
      [ :root_type, Mongo::ASCENDING ],
      [ :mentions, Mongo::DESCENDING ],
      [ :p, Mongo::DESCENDING ]
    ]
  )
  index(
    [
      [ :root_type, Mongo::DESCENDING ],
      [ :mentions, Mongo::DESCENDING ],
      [ :last_response_time, Mongo::DESCENDING ]
    ]
  )

  def created_at
    id.generation_time
  end

  class << self

    #TODO: latest response time?

    def post_create(post)
      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      root_type = post.root_type == 'Topic' ? post.class.name : post.root_type

      updates = {"$set" => { :last_response_time => Time.now, :root_type => root_type, }}
      updates["$addToSet"] = { "mentions" => { "$each" => post.topic_mention_ids } }

      FeedTopicItem.collection.update({:root_id => root_id}, updates, {:upsert => true})
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

      FeedTopicItem.destroy_all(conditions: { :root_id => post.id }) if root_id == post.id
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
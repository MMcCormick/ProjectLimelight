class FeedTopicItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :root_id
  field :root_type
  field :mentions
  field :root_mentions
  field :responses
  field :p, :default => 0

  class << self

    #TODO: latest response time?

    def post_create(post)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}

      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      root_type = post.root_type == 'Topic' ? post.class.name : post.root_type

      updates = {"$set" => { :last_response_time => Time.now, :root_type => root_type, }}
      updates["$addToSet"] = { "mentions" => { "$each" => topic_mention_ids } }
      if root_id == post.id
        updates["$set"]["root_mentions"] = topic_mention_ids
      else
        topic_mention_ids.each{ |m| updates["$set"]["responses."+m.to_s] = post.id }
      end

      FeedTopicItem.collection.update({:root_id => root_id}, updates, {:upsert => true})
    end

    def post_disable(post)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}

      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id

      if root_id == post.id
        FeedTopicItem.destroy_all(conditions: { :root_id => post.id })
      else
        item = FeedTopicItem.first(conditions: { :root_id => root_id })
        updates = {"$unset" => {}}
        updates["$pullAll"] = { "mentions" => topic_mention_ids.select{ |tm| !item.root_mentions || !item.root_mentions.include?(tm) } }
        topic_mention_ids.each{ |m| updates["$unset"]["responses."+m.to_s] = post.id }
        FeedTopicItem.collection.update({:root_id => root_id}, updates, {:upsert => true})
      end
    end
  end
end
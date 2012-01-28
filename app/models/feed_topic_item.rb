class FeedTopicItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :root_id
  field :root_type
  field :mentions
  field :root_mentions
  field :responses

  class << self

    #TODO: latest response time?

    def post_create(post)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}

      # warning: do not use post.is_root? in this function, since topic roots are excluded
      if post.class.name == 'Talk' && post.root_type != 'Topic'
        root_id = post.root_id
        root_type = post.root_type
      else
        root_id = post.id
        root_type = post.class.name
      end

      updates = {"$set" => { :last_response_time => Time.now, :root_type => root_type, }}
      updates["$addToSet"] = { "mentions" => { "$each" => topic_mention_ids } }
      if root_id == post.id
        updates["$set"].merge!({ :root_mentions => topic_mention_ids })
      else
        responses = {}
        topic_mention_ids.each{ |m| responses["responses."+m.to_s] = post.id }
        updates["$set"].merge!(responses)
      end

      FeedTopicItem.collection.update({:root_id => root_id}, updates, {:upsert => true})
    end
  end
end
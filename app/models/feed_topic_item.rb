class FeedTopicItem
  include Mongoid::Document
  include Mongoid::Timestamps

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

  class << self

    #TODO: latest response time?

    def post_create(post)
      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      root_type = post.root_type == 'Topic' ? post.class.name : post.root_type

      updates = {"$set" => { :last_response_time => Time.now, :root_type => root_type, }}
      updates["$addToSet"] = { "mentions" => { "$each" => post.mentioned_topic_ids } }

      FeedTopicItem.collection.update({:root_id => root_id}, updates, {:upsert => true})
    end

    def post_disable(post)
      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id

      FeedTopicItem.destroy_all(conditions: { :root_id => post.id }) if root_id == post.id
    end
  end
end
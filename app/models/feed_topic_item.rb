class FeedTopicItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :root_id
  field :root_type
  field :mentions
  field :root_mentions
  field :latest_responses, :type => Hash
  field :last_response_time, :type => DateTime

  class << self
    def post_create(post, popular_talk=false)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}

      # warning: do not use post.is_root? in this function, since topic roots are excluded
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      root_type = post.root_type == 'Topic' ? 'Talk' : post.root_type

      latest_responses

      # TODO: need positional operator $ to update latest_responses in place
      # TODO: but $ can't be used with upsert, so: need to refactor into separate queries for root objs and responses
      updates = {"$set" => { :last_response_time => Time.now }}
      if root_id == post.id
        updates["$set"] = { :root_type => root_type, :root_mentions => topic_mention_ids }
      else
        updates["$addToSet"] = { :latest_responses => 'foobar' }
      end

      FeedTopicItem.collection.update({:root_id => root_id}, updates, {:upsert => true})
    end
  end
end
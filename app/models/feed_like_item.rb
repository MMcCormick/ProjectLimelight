class FeedLikeItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, :type => BSON::ObjectId
  field :root_id
  field :root_type
  field :strength
  field :responses, :type => Array
  field :last_response_time, :type => DateTime

  class << self
    def like(user, post)
      updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      updates["$addToSet"] = { :responses => post.id } unless post.is_root?
      updates["$inc"] = { :strength => 1 }

      FeedLikeItem.collection.update({:feed_id => user.id, :root_id => post.root_id}, updates, {:upsert => true})
    end

    def unlike(user, post)
      updates = {"$inc" => { :strength => -1 }}
      updates["$pull"] = { :responses => post.id } unless post.is_root?
      FeedLikeItem.collection.update({:feed_id => user.id, :root_id => post.root_id }, updates)
      FeedLikeItem.delete_all(conditions: { :feed_id => user.id, :strength => {"$lte" => 0} })
    end
  end
end
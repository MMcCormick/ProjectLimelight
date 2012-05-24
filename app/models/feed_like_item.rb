class FeedLikeItem
  include Mongoid::Document

  field :user_id, :type => BSON::ObjectId
  field :root_id
  field :root_type
  field :strength
  field :responses, :type => Array
  field :last_response_time, :type => DateTime
  field :p, :default => 0

  index(
    [
      [ :feed_id, Mongo::DESCENDING ],
      [ :root_id, Mongo::DESCENDING ]
    ],
    unique: true
  )
  index(
    [
      [ :feed_id, Mongo::DESCENDING ],
      [ :root_type, Mongo::DESCENDING ],
      [ :last_response_time, Mongo::DESCENDING ]
    ]
  )
  index(
    [
      [ :feed_id, Mongo::DESCENDING ],
      [ :root_type, Mongo::DESCENDING ],
      [ :p, Mongo::DESCENDING ]
    ]
  )

  def created_at
    id.generation_time
  end

  class << self
    def create(user, post)
      updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      updates["$addToSet"] = { :responses => post.id } unless post.is_root?
      updates["$inc"] = { :strength => 1 }

      FeedLikeItem.collection.update({:feed_id => user.id, :root_id => post.root_id}, updates, {:upsert => true})
    end

    def destroy(user, post)
      updates = {"$inc" => { :strength => -1 }}
      updates["$pull"] = { :responses => post.id } unless post.is_root?
      FeedLikeItem.collection.update({:feed_id => user.id, :root_id => post.root_id }, updates)
      FeedLikeItem.delete_all(conditions: { :feed_id => user.id, :root_id => post.root_id, :strength => {"$lte" => 0} })
    end

    def post_destroy(post)
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      FeedLikeItem.destroy_all(conditions: { :root_id => root_id })
    end
  end
end
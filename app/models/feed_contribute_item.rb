class FeedContributeItem
  include Mongoid::Document
  include Mongoid::Timestamps

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

  class << self
    def create(post)
      updates = {"$set" => { :root_type => post.root_type, :last_response_time => Time.now }}
      updates["$addToSet"] = { :responses => post.id } unless post.is_root?
      updates["$inc"] = { :strength => 1 }

      FeedContributeItem.collection.update({:feed_id => post.user_snippet.id, :root_id => post.root_id}, updates, {:upsert => true})
    end

    def disable(post)
      updates = {"$inc" => { :strength => -1 }}
      updates["$pull"] = { :responses => post.id } unless post.is_root?
      FeedContributeItem.collection.update({:feed_id => post.user_snippet.id, :root_id => post.root_id }, updates)
      FeedContributeItem.delete_all(conditions: { :feed_id => post.user_snippet.id, :root_id => post.root_id, :strength => {"$lte" => 0} })
    end

    def post_destroy(post)
      FeedContributeItem.destroy_all(conditions: { :root_id => post.id })
    end
  end
end
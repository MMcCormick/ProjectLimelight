class FeedItem
  include Mongoid::Document

  field :feed_id, :type => BSON::ObjectId
  field :feed_type
  field :root_id
  field :root_type
  field :strength
  field :responses, :type => Array
  field :last_response_time, :type => DateTime

end
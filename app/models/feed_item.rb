class FeedItem
  include Mongoid::Document

  field :feed_id, :type => BSON::ObjectId
  field :feed_type
  field :root_id
  field :root_type
  field :strength
  field :responses, :type => Array
  field :last_response_time, :type => DateTime

  class << self
    def post_create(post)
      topic_mention_ids = post.topic_mentions.map{|tm| tm.id}
      user_mention_ids = post.user_mentions.map{|um| um.id}
      user_feed_users = User.only(:id, :following_topics, :following_users).any_of({:_id => {'$in' => user_mention_ids}}, {:following_users => post.user_snippet.id}, {:following_topics => {'$in' => topic_mention_ids}}).to_a

      if post.parent_id
        root_id = post.parent_id
        root_type = post.root_type
      elsif post.primary_topic_mention
        root_id = post.primary_topic_mention
        root_type = 'Topic'
      else
        root_id = post.id
        root_type = post._type
      end

      updates = {"$set" => {
                        :root_type => root_type,
                        :last_response_time => Time.now
                }}
      updates["$push"] = { :responses => post.id } unless root_id == post.id

      user_feed_users.each do |u|
        strength = 0
        strength += (topic_mention_ids & u.following_topics).length
        strength += 1 if u.following_users.include?(post.user_snippet.id)
        strength += 1 if user_mention_ids.include?(u.id)
        updates["$inc"] = { :strength => strength }

        FeedItem.collection.update(
          {:feed_id => u.id, :feed_type => 'uf', :root_id => root_id},
          updates,
          {:upsert => true}
        )
      end
    end

    def follow(user, topic)
      CoreObject.where(:topic_mentions.id => topic.id).each do |post|
        updates = {"$set" => {
                          :root_type => post.parent_type ? post.parent_type : "Topic",
                          :last_response_time => Time.now
                  }}
        updates["$push"] = { :responses => post.id }

        strength = 0
        strength += topic_intersection.length
        strength += 1 if u.following_users.include?(post.user_snippet.id)
        strength += 1 if user_mention_ids.include?(user.id)
        updates["$inc"] = { :strength => strength }

        FeedItem.collection.update(
          {:feed_id => user.id, :feed_type => 'uf', :root_id => post.parent_id ? post.parent_id : topic.id},
          updates,
          {:upsert => true}
        )
      end
    end
  end
end
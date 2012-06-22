class FeedContributeItem
  include Mongoid::Document

  field :user_id, :type => BSON::ObjectId
  field :root_id
  field :root_type
  field :strength, :default => 0
  field :responses, :default => []
  field :last_response_time, :type => DateTime
  field :p, :default => 0
  field :topic_ids, :default => []

  index({ :root_id => -1, :feed_id => -1 }, { :unique => true })
  index({ :feed_id => -1, :last_response_time => -1, :topic_ids => 1 })
  index({ :feed_id => -1, :p => -1, :topic_ids => 1 })

  def created_at
    id.generation_time
  end

  def reset_topic_ids
    if root_type == 'Talk'
      posts = [Post.find(root_id)]
    else
      posts = Post.where(:_id => {"$in" => responses})
    end

    self.topic_ids = posts.map{|p| p.topic_mention_ids}.flatten.uniq
  end

  class << self
    def create(post, backlog=true)
      item = FeedContributeItem.find_or_initialize_by(:feed_id => post.user_id, :root_id => post.root_id)
      unless item.responses.include?(post.id)
        item.root_type = post.root_type
        item.last_response_time = backlog ? post.created_at : Time.now
        item.responses << post.id unless post.is_root?
        item.strength += 1

        post.topic_mention_ids.each do |t|
          item.topic_ids << t unless item.topic_ids.include?(t)
        end

        item.save
      end
    end

    def disable(post)
      FeedContributeItem.collection.find({:feed_id => post.user_id, :root_id => post.root_id}).
                                    update_all({
                                      "$inc" => {
                                        :strength => -1,
                                      },
                                      "$pull" => {
                                        :responses => post.id
                                      }
                                    })

      item = FeedContributeItem.where(:feed_id => post.user_id, :root_id => post.root_id).first
      if item
        if item.strength <= 0
          item.delete
        else
          item.reset_topic_ids
          item.save
        end
      end
    end

    def update_post_topics(post)
      items = FeedLikeItem.where(:root_id => post.root_id)
      items.each do |i|
        i.reset_topic_ids
        i.save

        user = User.find(feed_id)
        if user
          user.topic_activity_recalculate
          user.save
        end
      end
    end

    def post_destroy(post)
      FeedContributeItem.where(:root_id => post.root_id).destroy
    end
  end
end
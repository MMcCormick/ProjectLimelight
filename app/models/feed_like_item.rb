class FeedLikeItem
  include Mongoid::Document

  field :feed_id
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
    posts = Post.where(:_id => {"$in" => responses << root_id})

    self.topic_ids = posts.map{|p| p.topic_mention_ids}.flatten.uniq
  end

  class << self
    def create(user, post, backlog=false)
      item = FeedLikeItem.find_or_initialize_by(:feed_id => user.id, :root_id => post.root_id)
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

    def destroy(user, post)
      FeedLikeItem.collection.find({:feed_id => user.id, :root_id => post.root_id}).
                  update_all({
                    "$inc" => {
                      :strength => -1,
                    },
                    "$pull" => {
                      :responses => post.id
                    }
                  })

      item = FeedLikeItem.where(:feed_id => user.id, :root_id => post.root_id).first
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
          user.topic_likes_recalculate
          user.save
        end
      end
    end

    def post_destroy(post)
      FeedLikeItem.collection.find({:root_id => post.root_id}).
                  update_all({
                    "$inc" => {
                      :strength => -1,
                    },
                    "$pull" => {
                      :responses => post.id
                    }
                  })

      FeedLikeItem.where(:root_id => post.root_id, :strength => 0).destroy
    end
  end
end
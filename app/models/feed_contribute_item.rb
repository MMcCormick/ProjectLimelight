class FeedContributeItem
  include Mongoid::Document

  field :user_id, :type => BSON::ObjectId
  field :root_id
  field :root_type
  field :strength, :default => 0
  field :responses, :default => []
  field :last_response_time, :type => DateTime
  field :p, :default => 0

  index({ :root_id => -1, :feed_id => -1 }, { :unique => true })
  index({ :feed_id => -1, :last_response_time => -1 })
  index({ :feed_id => -1, :p => -1 })

  def created_at
    id.generation_time
  end

  class << self
    def create(post)
      item = FeedContributeItem.find_or_initialize_by(:feed_id => post.user_id, :root_id => post.root_id)
      unless item.responses.include?(post.id)
        item.root_type = post.root_type
        item.last_response_time = Time.now
        item.responses << post.id unless post.is_root?
        item.strength += 1
        item.save
      end
    end

    def disable(post)
      FeedContributeItem.collection.where(:feed_id => post.user_id, :root_id => post.root_id).
                                    update_all(
                                      "$inc" => {
                                        :strength => -1,
                                      },
                                      "$pull" => {
                                        :responses => post.id
                                      }
                                    )
      FeedContributeItem.where(:feed_id => post.user_id, :root_id => post.root_id, :strength => {"$lte" => 0}).delete
    end

    def post_destroy(post)
      root_id = post.root_type == 'Topic' ? post.id : post.root_id
      FeedContributeItem.where(:root_id => root_id).destroy
    end
  end
end
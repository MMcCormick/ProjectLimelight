require 'json'

class FeedsLike
  include Resque::Plugins::UniqueJob

  @queue = :feeds

  def self.perform(post_id)

    post = CoreObject.find(post_id)
    post.push_like if post

  end

end
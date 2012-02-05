require 'json'

class FeedsUnlike
  include Resque::Plugins::UniqueJob

  @queue = :feeds

  def self.perform(post_id)

    post = CoreObject.find(post_id)
    post.push_unlike if post

  end

end
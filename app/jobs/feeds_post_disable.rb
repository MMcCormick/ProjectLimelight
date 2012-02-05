require 'json'

class FeedsPostDisable
  @queue = :feeds

  def self.perform(post_id)

    post = CoreObject.find(post_id)
    post.push_disable if post

  end

end
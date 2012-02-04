require 'json'

class FeedsPopularTalk
  include Resque::Plugins::UniqueJob

  @queue = :feeds

  def self.perform(post_id)

    post = CoreObject.find(post_id)
    post.push_popular_talk if post

  end

end
#require 'json'
#
#class FeedsUnlike
#  @queue = :feeds
#
#  def self.perform(post_id)
#
#    post = CoreObject.find(post_id)
#    user = User.find(user_id)
#    post.push_unlike(user) if post && user
#
#  end
#
#end
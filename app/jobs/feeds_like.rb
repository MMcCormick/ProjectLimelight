#require 'json'
#
#class FeedsLike
#  @queue = :feeds
#
#  def self.perform(post_id, user_id)
#
#    post = CoreObject.find(post_id)
#    user = User.find(user_id)
#    post.push_like(user) if post && user
#
#  end
#
#end
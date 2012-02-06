#require 'json'
#
#class FeedsPostCreate
#
#  @queue = :feeds
#
#  def self.perform(post_id)
#
#    post = CoreObject.find(post_id)
#    post.push_to_feeds if post
#
#  end
#
#end
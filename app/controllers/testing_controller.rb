require "net/http"

class TestingController < ApplicationController

  def test
    #authorize! :manage, :all
    #
    #@count1 = 0
    #@count2 = 0

    #Resque.enqueue(TestJob)

    #data = [
    #  [[2,3,4],[2,3,5]],
    #  [[2,3,4],[2,3,5]],
    #  [[1,2,3,4],[1,2,3,5]],
    #  [[8,7,6,4],[6,7,8,5],[8,7,10]],
    #  [[7,6,5],[7,6,4],[7,10]],
    #  [[7,6,5],[7,6,4],[7,10]],
    #  [10]
    #]

    PostMedia.each do |pm|
      pm.shares = []
      pm.ll_score = 0
      pm.comments = []
      pm.comment_count = 0
      pm.save
    end

    Post.all.each do |p|
      media = p.post_media

      unless media
        p.destroy
        next
      end

      media.add_share(p.user_id, p.content, p.topic_mention_ids, [], {:limelight => nil})

      p.comments.each do |c|
        media.add_comment(c.user_id, c.content)
      end
      media.save
    end

    PostMedia.each do |pm|
      pm.shares.each do |s|
        FeedUserItem.push_post_through_users(pm, s.user, false, true)
        FeedUserItem.push_post_through_topics(pm)
      end
    end

    #post = PostMedia.first
    #post.shares.each do |s|
    #  FeedUserItem.push_post_through_users(post, s.user, false, true)
    #end

  end

end
require "net/http"
include EmbedlyHelper

class TestingController < ApplicationController

  def test

    authorize! :manage, :all

    #tweets = Twitter.user_timeline('garrytan', :count => 50, :exclude_replies => true, :include_entities => true)
    #post = PostMedia.first
    #post.set_base_scores
    #PullTweets.perform
    #@count1 = 0
    #@count2 = 0

    Resque.enqueue(TestJob)

  end

end
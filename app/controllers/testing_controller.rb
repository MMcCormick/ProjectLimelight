require "net/http"
include EmbedlyHelper

class TestingController < ApplicationController

  def test

    authorize! :manage, :all

    post = PostMedia.first
    post.set_base_scores
    bar = 'foo'
    #PullTweets.perform
    #@count1 = 0
    #@count2 = 0

    #Resque.enqueue(TestJob)

  end

end
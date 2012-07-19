require "net/http"
include EmbedlyHelper

class TestingController < ApplicationController

  def test

    PullTweets.perform

    #authorize! :manage, :all
    #
    #@count1 = 0
    #@count2 = 0

    #Resque.enqueue(TestJob)

  end

end
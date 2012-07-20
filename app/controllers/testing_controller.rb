require "net/http"
include EmbedlyHelper

class TestingController < ApplicationController

  def test

    authorize! :manage, :all

    foo = PostMedia.find('500869cf5ae18c36680000d8')
    bar = 'foo'
    #PullTweets.perform
    #@count1 = 0
    #@count2 = 0

    #Resque.enqueue(TestJob)

  end

end
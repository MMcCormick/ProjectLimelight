require "net/http"

class TestingController < ApplicationController

  def test
    #authorize! :manage, :all
    #
    #@count1 = 0
    #@count2 = 0

    Resque.enqueue(TestJob)

  end

end
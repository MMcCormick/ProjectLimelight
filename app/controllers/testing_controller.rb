require "net/http"

class TestingController < ApplicationController

  def test
    #authorize! :manage, :all
    #
    #@count1 = 0
    #@count2 = 0

    Resque.enqueue(TestJob)

    #data = [
    #  [[2,3,4],[2,3,5]],
    #  [[2,3,4],[2,3,5]],
    #  [[1,2,3,4],[1,2,3,5]],
    #  [[8,7,6,4],[6,7,8,5],[8,7,10]],
    #  [[7,6,5],[7,6,4],[7,10]],
    #  [[7,6,5],[7,6,4],[7,10]],
    #  [10]
    #]

  end

end
require "net/http"

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    Resque.enqueue(TestJob)

  end

end
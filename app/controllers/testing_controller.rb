require "net/http"

class Controller
  attr_accessor :_prefixes
  def params() {} end
end

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    Resque.enqueue(TestJob)
  end

end
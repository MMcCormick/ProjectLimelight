require "net/http"

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    Resque.enqueue(TestJob)
    Resque.enqueue(SmDestroyUser, User.limelight_user_id)
  end

end
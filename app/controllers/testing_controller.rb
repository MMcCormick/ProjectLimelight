require "net/http"

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    #Resque.enqueue(TestJob)

    Notification.each do |n|
      if [:repost, :comment, :also].include?(n.type.to_sym)
        unless n.object
          n.destroy
        end
      end
    end

  end

end
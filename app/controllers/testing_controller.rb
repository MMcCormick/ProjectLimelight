class TestingController < ApplicationController

  def test
    @topic_wall = TopicWall.new
    @topic_wall.set_tags(@topic_wall.test_tags)
    @topic_wall.compute
    foo = 'bar'
  end

end
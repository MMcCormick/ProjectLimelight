require "net/http"

class Controller
  attr_accessor :_prefixes
  def params() {} end
end

class TestingController < ApplicationController

  def test
    authorize! :manage, :all

    Post.all.destroy
    FeedUserItem.all.delete
    FeedTopicItem.all.delete
    FeedContributeItem.all.delete
    PopularityAction.all.delete

    User.update_all(:score => 0)
    Topic.update_all(:score => 0)

    @destroyed = 0
    @updated = 0
    topics = Topic.all
    topics.each do |t|
      if t.followers_count == 0 && !t.primary_type_id && !t.fb_page_id && !t.is_category && t.image_versions == 0
        t.destroy
        @destroyed += 1
      else
        t.talking_ids = []
        t.response_count = 0
        t.influencers = {}
        t.save
        @updated += 1
      end
    end
  end

end
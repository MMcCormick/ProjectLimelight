class TestingController < ApplicationController

  def test
    RecalculatePopularity.perform
  end

  def foo
    # get all objects
    CoreObject.all.each do |co|

      # do we need to split a link into a talk?
      if co._type != 'Talk' && !co.content.blank?
        Talk.create(
          :content => co.content,
          :content_raw => co.content,
          :user_id => co.user_id,
          :parent => co
        )
        co.content = ''
      end

      co.set_root
      co.save
    end

    # loop through all core objects and push to feeds
    CoreObject.all.each do |co|
      if co.id.to_s == '4f0b420ebb30bd000500011e'
        foo = 'bar'
      end

      # set the primary topic mention
      mentions = Topic.where(:_id => {'$in' => co.topic_mentions.map{|t| t.id}}).to_a
      mentions.each do |topic|
        if !co.primary_topic_pm || topic.pt > co.primary_topic_pm
          co.primary_topic_mention = topic.id
          co.primary_topic_pm = topic.pm
        end
      end
      co.save

      FeedUserItem.post_create(co)
      FeedTopicItem.post_create(co) unless co.class.name == 'Talk' || co.topic_mentions.empty?
      FeedContributeItem.create(co)
    end
  end

end
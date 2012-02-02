class TestingController < ApplicationController

  def test

    map    = "function() {
      var hours = this.et;
      this.pop_snippets.forEach(function(snippet) {
        if(snippet.ot == 'User' || snippet.ot == 'Topic' || (snippet.ot == 'Talk' && snippet.rt == 'Topic')) {
          emit(snippet._id, {amount: snippet.a, type: snippet.ot, temp_time: hours});
        }
        if(snippet.ot == 'Video' || snippet.ot == 'Picture' || snippet.ot == 'Link' || snippet.ot == 'Talk')
        {
          emit(snippet.rid, {amount: snippet.a, type: snippet.rt, temp_time: hours});
        }
      });
    };"
    reduce = "function(key, values) {
      var result = {amount: 0, type: values[0].type, temp_time: values[0].temp_time}

      values.forEach(function(doc) {
        result.amount += doc.amount
      });

      return result;
    };"

    @results = PopularityAction.collection.map_reduce(map, reduce, :query => {:et => {'$gte' => Chronic.parse("three months ago").utc.to_i}}, :out => "popularity_results")

  end

  # temporarily excluded for faster testing of above
  def testrest
    ###############################
    # AVERAGES

    map2    = "function() {
      emit(this.value.type, {amount: this.value.amount});
    };"
    reduce2 = "function(key, values) {
      var sum = 0;
      var count = 0;
      var average = 0;
      values.forEach(function(doc) {
        sum += doc.amount;
        count += 1;
      });
      if (count > 0)
        average = sum/count;
      return {amount: average};
    };"

    @results2 = PopularityResults.collection.map_reduce(map2, reduce2, :out => "popularity_averages")

    averages2 = SiteData.where(:name => 'object_averages').first
    averages2 = SiteData.new(:name => 'object_averages') unless averages2
    @results2.find().each do |doc|
      averages2.data[doc['_id']] = doc['value']['amount']
    end
    averages2.save

    # END AVERAGES

    averages = SiteData.where(:name => 'object_averages').first
    if averages
      averages.data.delete('User')
      normalized_average = averages.data.values.inject{ |sum, el| sum + el }.to_f / averages.data.size
      normalized = {
              :topic => normalized_average/averages.data['Topic'],
              :link => normalized_average/averages.data['Link'],
              :picture => normalized_average/averages.data['Picture'],
              :video => normalized_average/averages.data['Video'],
              :talk => normalized_average/averages.data['Talk']
      }
    else
      normalized = {
              :topic => 1,
              :link => 1,
              :picture => 1,
              :video => 1,
              :talk => 1
      }
    end

    @results.find().each do |doc|
      # Normalize the popularity
      normalized_value = doc["value"]["amount"]
      case doc["value"]["type"]
        when 'Topic'
          normalized_value = normalized[:topic] * normalized_value
        when 'Link'
          normalized_value = normalized[:link] * normalized_value
        when 'Picture'
          normalized_value = normalized[:picture] * normalized_value
        when 'Video'
          normalized_value = normalized[:video] * normalized_value
        when 'Talk'
          normalized_value = normalized[:talk] * normalized_value
      end

      FeedTopicItem.where(:root_id => doc["_id"]).update_all("p" => normalized_value)
      FeedLikeItem.where(:root_id => doc["_id"]).update_all("p" => normalized_value)
      FeedContributeItem.where(:root_id => doc["_id"]).update_all("p" => normalized_value)

      FeedUserItem.where(:root_id => doc["_id"]).each do |item|
        item.ds = item.ds * (1 - (Time.now - item.dt) / 360000) if item.dt
        item.p = normalized_value
        item.rel = item.p * item.ds
        item.dt = Time.now
        item.save
      end
    end

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
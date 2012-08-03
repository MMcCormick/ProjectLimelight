class RecalculatePopularity
  include Resque::Plugins::UniqueJob
  include PopularityHelper

  @queue = :slow_limelight

  def self.perform
    map    = "function() {
      var hours = (#{Time.now.utc.to_i} - this.et) / 3600;
      if (hours < 1) { hours = 1 }
      this.pop_snippets.forEach(function(snippet) {
        if(snippet.ot == 'User' || snippet.ot == 'Topic' || (snippet.ot == 'Post' && snippet.rt == 'Topic')) {
          emit(snippet._id, {amount: snippet.a / Math.pow(hours, 0.15), type: snippet.ot});
        }
        if(snippet.ot == 'Video' || snippet.ot == 'Picture' || snippet.ot == 'Link' || snippet.ot == 'Post')
        {
          emit(snippet.rid, {amount: snippet.a / Math.pow(hours, 0.15), type: snippet.rt});
        }
      });
    };"
    reduce = "function(key, values) {
      var result = {amount: 0, type: values[0].type}

      values.forEach(function(doc) {
        result.amount += doc.amount
      });

      return result;
    };"

    averages = SiteData.where(:name => 'object_averages').first
    if averages
      averages.data.delete('User')
      normalized_average = averages.data.values.inject{ |sum, el| sum + el }.to_f / averages.data.size
      normalized = {
              :topic => normalized_average/averages.data['Topic'],
              :link => normalized_average/averages.data['Link'],
              :picture => normalized_average/averages.data['Picture'],
              :video => normalized_average/averages.data['Video'],
              :post => normalized_average/averages.data['Post']
      }
    else
      normalized = {
              :topic => 1,
              :link => 1,
              :picture => 1,
              :video => 1,
              :post => 1
      }
    end

    PopularityAction.where(:et => {'$gte' => Chronic.parse("three months ago").utc.to_i}).map_reduce(map, reduce).out(:replace => "popularity_results").each do |doc|
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
        when 'Post'
          normalized_value = normalized[:post] * normalized_value
      end

      FeedTopicItem.where(:root_id => doc["_id"]).update_all("p" => normalized_value)
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

end
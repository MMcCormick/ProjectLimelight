class RecalculateAverages
  include Resque::Plugins::UniqueJob

  @queue = :slow

  def self.perform
    map    = "function() {
      emit(this.value.type, {amount: this.value.amount});
    };"
    reduce = "function(key, values) {
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

    averages = SiteData.where(:name => 'object_averages').first
    averages = SiteData.new(:name => 'object_averages') unless averages

    PopularityResults.map_reduce(map, reduce).out(:replace => "popularity_averages").each do |doc|
      averages.data[doc['_id']] = doc['value']['amount']
    end

    averages.save
  end

end
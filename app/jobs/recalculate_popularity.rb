class RecalculatePopularity
  include Resque::Plugins::UniqueJob
  include PopularityHelper

  @queue = :popularity

  def initialize(timeframe)
    map    = "function() { " +
      "this.pop_snippets.forEach(function(snippet) { " +
      " emit(snippet._id, {amount: snippet.a, type: snippet.ot}); " +
      "}); " +
    "};"
    reduce = "function(key, values) { " +
      "var sum = 0; " +
      "values.forEach(function(doc) { " +
      " sum += doc.amount; " +
      "}); " +
      "var otype = values[0].type; " +
      "return {amount: sum, type: otype}; " +
    "};"

    @results = PopularityAction.collection.map_reduce(map, reduce, :query => {:created_at => {'$gte' => Chronic.parse("one "+timeframe+" ago")}}, :out => timeframe+"_results")

    set_pop(CoreObject.where("p"+timeframe[0,1]+"c" => true), timeframe)
    set_pop(Comment.where("p"+timeframe[0,1]+"c" => true), timeframe)
    set_pop(User.where("p"+timeframe[0,1]+"c" => true), timeframe)
    set_pop(Topic.where("p"+timeframe[0,1]+"c" => true), timeframe)
  end

  def self.perform(timeframe)
    new(timeframe)      
  end
end
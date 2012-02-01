class RecalculatePopularity
  include Resque::Plugins::UniqueJob
  include PopularityHelper

  @queue = :popularity

  def initialize
    map    = "function() { " +
      "this.pop_snippets.forEach(function(snippet) { " +
      "  if(snippet.ot == 'User' || snippet.ot == 'Topic' || (snippet.ot == 'Talk' && snippet.rt == 'Topic')) {" +
      "  emit(snippet._id, {amount: snippet.a, type: snippet.ot}); " +
      "  }" +
      "  if(snippet.ot == 'Video' || snippet.ot == 'Picture' || snippet.ot == 'Link' || snippet.ot == 'Talk') " +
      "  emit(snippet.rid, {amount: snippet.a, type: snippet.ot}); " +
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

    #take time into account?
    @results = PopularityAction.collection.map_reduce(map, reduce, :query => {}, :out => "pop_results")

  end

  def self.perform
    new
  end

  #def initialize(timeframe)
  #  map    = "function() { " +
  #    "this.pop_snippets.forEach(function(snippet) { " +
  #    " emit(snippet._id, {amount: snippet.a, type: snippet.ot}); " +
  #    "}); " +
  #  "};"
  #  reduce = "function(key, values) { " +
  #    "var sum = 0; " +
  #    "values.forEach(function(doc) { " +
  #    " sum += doc.amount; " +
  #    "}); " +
  #    "var otype = values[0].type; " +
  #    "return {amount: sum, type: otype}; " +
  #  "};"
  #
  #  @results = PopularityAction.collection.map_reduce(map, reduce, :query => {:created_at => {'$gte' => Chronic.parse("one "+timeframe+" ago").utc}}, :out => timeframe+"_results")
  #
  #  set_pop(CoreObject.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #  set_pop(Comment.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #  set_pop(User.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #  set_pop(Topic.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #end
end
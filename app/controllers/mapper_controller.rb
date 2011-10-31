class MapperController < ApplicationController
  #TODO: remove this controller after pop is all set

  def test
    users = User.all.asc(:pt)
    num_users = User.count

    users.each_with_index do |user, i|
      user.clout = 2.5 * (i+1) / num_users + 0.5
      user.save!
    end
  end

  #def test
  #  timeframe = "month"
  #
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
  #  @results = PopularityAction.collection.map_reduce(map, reduce, :query => {:created_at => {'$gte' => Chronic.parse("one "+timeframe+" ago")}}, :out => timeframe+"_results")
  #
  #  set_pop(CoreObject.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #  set_pop(Comment.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #  set_pop(User.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #  set_pop(Topic.where("p"+timeframe[0,1]+"c" => true), timeframe)
  #end
  #
  #def set_pop(objects, timeframe)
  #  objects.each do |object|
  #    pop_amount = 0
  #    @results.find("_id" => object.id).each do |doc|
  #      pop_amount = doc["value"]["amount"]
  #    end
  #    object.set("p"+timeframe[0,1], pop_amount)
  #    object["p"+timeframe[0,1]+"c"] = false
  #    object.save!
  #  end
  #end

end

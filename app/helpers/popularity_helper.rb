module PopularityHelper
  def set_pop(objects, timeframe)
    objects.each do |object|
      pop_amount = 0
      @results.find("_id" => object.id).each do |doc|
        pop_amount = doc["value"]["amount"]
      end
      object.set("p"+timeframe[0,1], pop_amount)
      object["p"+timeframe[0,1]+"c"] = false
      object.save!
    end
  end
end

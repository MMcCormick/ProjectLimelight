module PopularityHelper
  def set_pop(objects, timeframe)
    objects.each do |object|
      pop_amount = 0
      @results.find("_id" => object.id).each do |doc|
        pop_amount = doc["value"]["amount"]
      end
      object.set("p"+timeframe[0,1], pop_amount)
      object["p"+timeframe[0,1]+"c"] = false if pop_amount == 0

      if object.class.name == "Topic" && timeframe == "day"
        #Resque.enqueue(SmCreateTopic, object.id)
      end

      object.save!
    end
  end
end

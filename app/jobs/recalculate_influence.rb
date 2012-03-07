class RecalculateInfluence
  include Resque::Plugins::UniqueJob

  @queue = :popularity

  def self.perform(topic_id)
    topic = Topic.find(BSON::ObjectId(topic_id))

    array = topic.influencers.dup.to_a
    array = array.sort{ |a,b| a[1]["influence"] <=> b[1]["influence"] }

    #length = array.length
    array.each_with_index do |a, i|
      topic.influencers[a[0]]["percentile"] = ((i.to_f+1.0) * 100.0 / array.length.to_f).to_f
    end

    topic.save!
  end
end
class RecalculateInfluence
  include Sidekiq::Worker
  sidekiq_options :queue => :slow_limelight, :unique => true

  def perform(topic_id)
    topic = Topic.find(Moped::BSON::ObjectId(topic_id))

    array = topic.influencers.dup.to_a
    array = array.sort{ |a,b| a[1]["influence"] <=> b[1]["influence"] }

    user_to_beat = array[(array.length.to_f * 0.9).to_i]

    #length = array.length
    array.each_with_index do |a, i|
      percentile = ((i.to_f+1.0) * 100.0 / array.length.to_f).to_f
      topic.influencers[a[0]]["percentile"] = percentile
      topic.influencers[a[0]]["influencer"] = percentile > 90 ? true : false
      topic.influencers[a[0]]["rank"] = array.length - i
      topic.influencers[a[0]]["offset"] = user_to_beat[1]["influence"] - a[1]["influence"]
    end

    topic.save!
  end
end
class InfluencerTopic
  attr_accessor :topic, :influence, :influencer, :percentile, :rank

  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def as_json(options={})
    {
      :topic => topic.as_json,
      :influence => influence.to_i,
      :influencer => influencer,
      :percentile => percentile.to_i,
      :rank => rank
    }
  end
end
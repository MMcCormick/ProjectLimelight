class InfluenceIncrease
  attr_accessor :id, :amount, :topic_id, :topic, :object_type, :action, :reason

  def id
    @topic_id
  end

  def reason
    case @action
      when :lk
        "#{@topic[:name]}"
      when :new
        "You posted about #{@topic[:name]} for the first time"
    end
  end

  def setTopic(topic)
    @topic = {
            :id => topic.name,
            :_id => topic.id.to_s,
            :name => topic.name,
            :public_id => topic.public_id,
            :slug => topic.slug
    }
  end
end
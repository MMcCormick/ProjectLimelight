class InfluenceIncrease
  attr_accessor :id, :amount, :topic_id, :topic, :object_type, :action, :user_id, :user, :reason

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

  class << self
    def influence_increases
      increases = []
      actions = PopularityAction.order_by(:et, :desc).limit(50)
      actions.each do |action|
        action.pop_snippets.each do |snip|
          if snip.ot == "Topic" && snip.a > 0
            inc = InfluenceIncrease.new()
            inc.amount = snip.a
            inc.topic_id = snip.id
            inc.object_type = action.pop_snippets[0].ot
            inc.action = action.t
            inc.user_id = action.user_id
            increases << inc
          end
        end
      end

      topics = {}
      users = {}
      tmp_topics = Topic.where(:_id.in => increases.map{|i| i.topic_id})
      tmp_users = User.where(:_id.in => increases.map{|i| i.user_id})
      tmp_topics.each {|t| topics[t.id.to_s] = t}
      tmp_users.each {|u| users[u.id.to_s] = u}

      increases.each do |increase|
        increase.topic = topics[increase.topic_id.to_s]
        increase.user = users[increase.user_id.to_s]
      end
    end
  end
end
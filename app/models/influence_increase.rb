class InfluenceIncrease
  include ModelUtilitiesHelper
  include Mongoid::CachedJson

  attr_accessor :id, :amount, :topic_id, :topic, :object_type, :action, :user_id, :user, :triggered_by_id, :triggered_by, :reason, :post_id, :post, :created_at_pretty

  def id
    @topic_id
  end

  def reason
    case @action
      when :lk
        "#{@topic[:name]}"
      when :new
        "Posted about #{@topic[:name]} for the first time"
    end
  end

  def setTopic(topic)
    @topic = {
            :id => topic.name,
            :_id => topic.id.to_s,
            :name => topic.name,
            :slug => topic.slug
    }
  end

  def as_json(options={})
    {
            :id => Moped::BSON::ObjectId.new.to_s,
            :amount => amount,
            :reason => reason,
            :topic => topic.as_json,
            :user => user.as_json,
            :action => action,
            :topic_id => topic_id.to_s,
            :post => post ? post.as_json(:user => options[:user]) : nil,
            :triggered_by => triggered_by ? triggered_by.as_json() : nil,
            :created_at_pretty => created_at_pretty
    }
  end

  class << self
    def influence_increases
      increases = []
      actions = PopularityAction.desc(:et).limit(75)
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
      tmp_topics = Topic.where(:_id => {"$in" => increases.map{|i| i.topic_id}})
      tmp_users = User.where(:_id => {"$in" => increases.map{|i| i.user_id}})
      tmp_topics.each {|t| topics[t.id.to_s] = t}
      tmp_users.each {|u| users[u.id.to_s] = u}

      filtered_increases = []
      increases.each do |increase|
        topic = topics[increase.topic_id.to_s]
        if topic.active_image_version != 0
          increase.topic = topics[increase.topic_id.to_s]
          increase.user = users[increase.user_id.to_s]
          filtered_increases << increase
        end
      end
      filtered_increases
    end
  end
end
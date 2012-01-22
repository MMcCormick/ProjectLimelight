class TopicCell < Cell::Rails

  include Devise::Controllers::Helpers
  include CanCan::ControllerAdditions
  helper ApplicationHelper
  helper TopicsHelper

  cache :trending, :expires_in => 10.minutes do |cell,topic|
    topic.id.to_s
  end

  cache :sidebar do |cell,current_user,topic|
    key = topic.id.to_s
    if current_user && current_user.is_following?(topic)
      key += '-following'
    end
    if current_user && (current_user.role?('admin') || topic.permission?(current_user.id, :update))
      key += '-manage'
    end
    key
  end

  def sidebar(current_user, topic, connections=nil)
    @current_user = current_user
    @topic = topic
    @connections = connections ? connections : Neo4j.get_topic_relationships(@topic.id)
    @num_con_sugs = TopicConSug.any_of({topic1_id: @topic.id}, {topic2_id: @topic.id}).count()
    render
  end

  def add_connection(topic)
    @topic = topic
    @connection_types = TopicConnection.all.asc(:name)
    #@suggested_connections = @topic.suggested_connections
    render
  end

  def trending(topic=nil)
    if topic
      pull_ids = Neo4j.pull_from_ids(topic.id)
      if !pull_ids.empty?
        @trend_title = "Trending Topics related to "+topic.name+":"
      elsif topic.primary_type_id
        pull_ids = Neo4j.pull_from_ids(topic.primary_type_id)
        @trend_title = "Trending Topics related to "+topic.primary_type+":"
      else
        @trend_title = "There are no related trending topics to display"
      end
      @topics = Topic.where("_id" => {"$in" => pull_ids}).desc(:pw).limit(40) if !pull_ids.empty?
    else
      @topics = Topic.all.desc(:pw).limit(40)
    end
    render
  end

  def topic_suggestions(topic)
    @suggestions = Neo4j.topic_related(topic.id.to_s, 6)
    render
  end

end

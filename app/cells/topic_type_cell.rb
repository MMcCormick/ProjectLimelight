class TopicTypeCell < Cell::Rails
  def new(topic)
    @topic = topic
    @types = TopicType.all.asc(:name)
    @type = TopicType.new

    render
  end
end
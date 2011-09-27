class TopicTypeCell < Cell::Rails
  def new
    @topic = @opts[:topic]
    @types = TopicType.all.asc(:name)
    @type = TopicType.new

    render
  end
end
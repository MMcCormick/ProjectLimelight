class LL.Collections.TopicsByCategory extends Backbone.Collection
  url: '/api/topics/top_by_category'

  parse: (response) ->
    data = []
    for item in response
      group = {
        category: new LL.Models.Topic(item.category),
        topics: []
      }
      for topic in item.topics
        group.topics.push(new LL.Models.Topic(topic))

      data.push group

    data
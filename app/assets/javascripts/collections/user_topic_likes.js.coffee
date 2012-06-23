class LL.Collections.UserTopicLikes extends Backbone.Collection
  url: =>
    "/api/users/#{@user.get('slug')}/topic_likes"

  parse: (response) ->
    results = []

    for item in response
      results.push {
        count: item.count
        topic: new LL.Models.Topic(item.topic)
      }

    results
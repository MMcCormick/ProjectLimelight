class LL.Models.RootPost extends Backbone.Model

  initialize: ->
    used_ids = []

    if @get('root').type == 'Topic'
      @set('root', new LL.Models.Topic(@get('root')))
    else
      @set('root', new LL.Models.Post(@get('root')))

    like_responses = []
    for response in @get('like_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      like_responses.push(new LL.Models.Post(response))
    @set('like_responses', like_responses)

    activity_responses = []
    for response in @get('activity_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = new LL.Models.Post(response)
      activity_responses.push(response)
    @set('activity_responses', activity_responses)

    feed_responses = []
    for response in @get('feed_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      feed_responses.push(new LL.Models.Post(response))
    @set('feed_responses', feed_responses)
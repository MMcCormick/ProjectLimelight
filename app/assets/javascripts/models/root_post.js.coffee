class LL.Models.RootPost extends Backbone.Model

  initialize: ->
    used_ids = []

    if @get('root').type == 'Topic'
      @set('root', LL.App.Topics.findOrCreate(@get('root').id, @get('root')))
    else
      @set('root', LL.App.Posts.findOrCreate(@get('root').id, new LL.Models.Post(@get('root'))))

    personal_responses = []
    for response in @get('personal_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      personal_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
    @set('personal_responses', personal_responses)

    like_responses = []
    for response in @get('like_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      like_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
    @set('like_responses', like_responses)

    activity_responses = []
    for response in @get('activity_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      activity_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
    @set('activity_responses', activity_responses)

    public_responses = []
    for response in @get('public_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      public_responses.push(response)
    @set('public_responses', public_responses)
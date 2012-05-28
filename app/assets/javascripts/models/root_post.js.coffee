class LL.Models.RootPost extends Backbone.Model

  initialize: ->
    used_ids = []

    if @get('root').type == 'Topic'
      @set('root', new LL.Models.Topic(@get('root')))
    else
      @set('root', new LL.Models.Post(@get('root')))

    personal_responses = []
    for response in @get('personal_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      personal_responses.push(new LL.Models.Post(response))
    @set('personal_responses', personal_responses)

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

    public_responses = []
    for response in @get('public_responses')
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      public_responses.push(new LL.Models.Post(response))
    @set('public_responses', public_responses)
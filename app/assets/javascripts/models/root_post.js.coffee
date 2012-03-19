class LL.Models.RootPost extends Backbone.Model

  parse: (resp, xhr) ->
    return null unless resp.root

    used_ids = []

    data = {
      'public_talking': resp.public_talking
      'personal_talking': resp.personal_talking
    }

    if resp.root.type == 'Topic'
      data['root'] = LL.App.Topics.findOrCreate(resp.root.id, resp.root)
    else
      data['root'] = LL.App.Posts.findOrCreate(resp.root.id, new LL.Models.Post(resp.root))

    personal_responses = []
    for response in resp.personal_responses
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      personal_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
    data['personal_responses'] = personal_responses

    like_responses = []
    for response in resp.like_responses
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      like_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
    data['like_responses'] = like_responses

    activity_responses = []
    for response in resp.activity_responses
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      activity_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
    data['activity_responses'] = activity_responses

    public_responses = []
    for response in resp.public_responses
      continue if _.include(used_ids, response.id)
      used_ids.push response.id
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      public_responses.push(response)
    data['public_responses'] = public_responses

    data
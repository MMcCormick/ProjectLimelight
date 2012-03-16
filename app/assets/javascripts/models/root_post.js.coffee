class LL.Models.RootPost extends Backbone.Model

  parse: (resp, xhr) ->
    return null unless resp.root

    data = {
      'public_talking': resp.public_talking
      'personal_talking': resp.personal_talking
    }

    if resp.root.type == 'Topic'
      data['root'] = LL.App.Topics.findOrCreate(resp.root.id, resp.root)
    else
      data['root'] = LL.App.Posts.findOrCreate(resp.root.id, new LL.Models.Post(resp.root))
      data['root'].set('user', LL.App.Users.findOrCreate(data['root'].get('user').id, new LL.Models.User(data['root'].get('user'))))
      mentions = []
      for mention in data['root'].get('topic_mentions')
        mentions.push(LL.App.Topics.findOrCreate(mention.slug, mention))
      data['root'].set('topic_mentions', mentions)

    public_responses = []
    for response in resp.public_responses
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      public_responses.push(response)
      response.set('user', LL.App.Users.findOrCreate(response.get('user').id, new LL.Models.User(response.get('user'))))
      mentions = []
      for mention in response.get('topic_mentions')
        mentions.push(LL.App.Topics.findOrCreate(mention.slug, mention))
      response.set('topic_mentions', mentions)

    data['public_responses'] = public_responses

    personal_responses = []
    for response in resp.personal_responses
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      response.set('user', LL.App.Users.findOrCreate(response.get('user').id, new LL.Models.User(response.get('user'))))
      personal_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
      mentions = []
      for mention in response.get('topic_mentions')
        mentions.push(LL.App.Topics.findOrCreate(mention.slug, mention))
      response.set('topic_mentions', mentions)

    data['personal_responses'] = personal_responses

    like_responses = []
    for response in resp.like_responses
      response = LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response))
      response.set('user', LL.App.Users.findOrCreate(response.get('user').id, new LL.Models.User(response.get('user'))))
      like_responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))
      mentions = []
      for mention in response.get('topic_mentions')
        mentions.push(LL.App.Topics.findOrCreate(mention.slug, mention))
      response.set('topic_mentions', mentions)

    data['like_responses'] = like_responses

    data
class LL.Models.RootPost extends Backbone.Model

  parse: (resp, xhr) ->
    data = {}
    if resp.root.type == 'Topic'
      data['root'] = new LL.Models.Topic(resp.root)
    else
      data['root'] = LL.App.Posts.findOrCreate(resp.id, new LL.Models.Post(resp.root))

    responses = []
    for response in resp.responses
      responses.push(LL.App.Posts.findOrCreate(response.id, new LL.Models.Post(response)))

    data['responses'] = responses
    data
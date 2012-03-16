class LL.Models.Post extends Backbone.Model
  url: '/api/posts'

  initialize: ->
    if @get('user')
      @set('user', LL.App.Users.findOrCreate(@get('user').id, new LL.Models.User(@get('user'))))

    mentions = []
    if @get('topic_mentions')
      for mention in @get('topic_mentions')
        mentions.push(LL.App.Topics.findOrCreate(mention.slug, mention))

    @set('topic_mentions', mentions)

  # check if it's in the master identity map
  parse: (resp, xhr) ->
    LL.App.Posts.findOrCreate(resp.id, new LL.Models.Post(resp))

  scorePretty: ->
    parseInt @get('score')
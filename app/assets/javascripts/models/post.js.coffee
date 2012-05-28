class LL.Models.Post extends Backbone.Model
  url: '/api/posts'
  keepInSync: true
  name: 'post'

  initialize: ->
    if @get('user')
      @set('user', new LL.Models.User(@get('user')))

    mentions = []
    if @get('topic_mentions')
      for mention in @get('topic_mentions')
        mentions.push(new LL.Models.User(mention))

    @set('topic_mentions', mentions)

    likes = []
    if @get('likes')
      for user in @get('likes')
        likes.push(new LL.Models.User(user))
    @set('likes', likes)

    if !@get('comments')
      @set('comments', [])

    comments = []
    for comment in @get('comments')
      comments.push(new LL.Models.Comment(comment))
    @set('comments', comments)

  scorePretty: ->
    parseInt @get('score')
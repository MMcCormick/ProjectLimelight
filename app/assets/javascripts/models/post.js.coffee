class LL.Models.Post extends Backbone.Model
  url: '/api/posts'
  keepInSync: true
  name: 'post'

  initialize: ->
    @set('user', new LL.Models.User(@get('user')))

    mentions = []
    if @get('topic_mentions')
      for mention in @get('topic_mentions')
        mentions.push(new LL.Models.Topic(mention))
    @set('topic_mentions', mentions)

    @set('liked', if LL.App.current_user then _.include(@get('likes'), LL.App.current_user.get('id')) else false)

    likes = []
    if @get('recent_likes')
      for user in @get('recent_likes')
        likes.push(new LL.Models.User(user))
    @set('recent_likes', likes)

    comments = []
    if @get('comments')
      for comment in @get('comments')
        comments.push(new LL.Models.Comment(comment))
    @set('comments', comments)

  scorePretty: ->
    parseInt @get('score')
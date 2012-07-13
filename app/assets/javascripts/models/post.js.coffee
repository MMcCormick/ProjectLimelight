class LL.Models.Post extends Backbone.Model
  keepInSync: true
  name: 'post'
  urlRoot: "/api/posts"

  initialize: ->
    @set('user', new LL.Models.User(@get('user')))

    if @get('media')
      @set('media', new LL.Models.PostMedia(@get('media')))

    mentions = []
    if @get('topic_mentions')
      for mention in @get('topic_mentions')
        mentions.push(new LL.Models.Topic(mention))
    @set('topic_mentions', mentions)

    comments = []
    if @get('comments')
      for comment in @get('comments')
        comments.push(new LL.Models.Comment(comment))
    @set('comments', comments)

    channel = LL.App.get_subscription("#{@get('id')}")
    unless channel
      channel = LL.App.subscribe("#{@get('id')}")

    # listen to the channel for new comments
    self = @
    unless LL.App.get_event_subscription("#{@get('id')}", 'new_comment')
      channel.bind 'new_comment', (data) ->
        comment = new LL.Models.Comment(data)
        self.addComment(comment)

  scorePretty: ->
    parseInt @get('score')

  fetchComments: =>
    self = @
    @comments = new LL.Collections.Comments
    @comments.fetch data: {id: @get('id')}, success: (collection,response) ->
      comments = []
      for comment in response
        comments.push(new LL.Models.Comment(comment))
      self.set('comments', comments)
      self.trigger('reset_comments')

  addComment: (comment) =>
    comments = @get('comments')
    comment = new LL.Models.Comment(comment)
    comments.push(comment)
    @set('comments', comments)
    @trigger('new_comment', comment)
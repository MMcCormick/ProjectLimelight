class LL.Views.PostShow extends Backbone.View
  template: JST['posts/show']
  id: 'post-show'
  className: 'content-tile'

  events:
    "click .friend-responses input": "showTalkForm"

  initialize: ->
    @friendResponsesCollection = new LL.Collections.PostFriendResponses()
    @publicResponsesCollection = new LL.Collections.PostPublicResponses()
    @friendResponses = new LL.Views.PostShowResponses(collection: @friendResponsesCollection)
    @friendResponses.type = 'FriendResponses'
    @publicResponses = new LL.Views.PostShowResponses(collection: @publicResponsesCollection)
    @publicResponses.type = 'PublicResponses'
    @loaded = null

    @model.on('change', @render)

  render: =>
    return unless @model
    $(@el).html(@template(post: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    topic_section = new LL.Views.TopicSectionList()
    topic_section.topics = @model.get('topic_mentions')
    $(@el).find('.half-sections').append(topic_section.render().el)

    user_section = new LL.Views.UserSectionList()
    user_section.users = @model.get('recent_likes')
    user_section.count = @model.get('likes').length
    $(@el).find('.half-sections').append(user_section.render().el)

    $(@el).find('.post-responses').append(@friendResponses.el).append(@publicResponses.el)

    view = new LL.Views.PostForm()
    view.placeholder_text = "Talk about this #{@model.get('type')}..."
    $(@el).find('.post-responses .talk-form').html(view.render().el)
    i = 1
    for topic in @model.get('topic_mentions')
      view.addTopic($(view.el).find("#post-form-mention#{i}"), topic.get('name'), topic.get('id'))
      break if i == 2
      i++
    view.model.set('parent_id', @model.get('id'))
    $(view.el).find('.icons').remove()

    unless @loaded

      @friendResponsesCollection.fetch({data: {id: @model.get('id')}})
      @publicResponsesCollection.fetch({data: {id: @model.get('id')}})

    @loaded = true

    if LL.App.Feed
      $(@el).addClass('modal')

    @

  showTalkForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    $(@el).find('.talk-form').fadeIn(250).find('textarea').focus()
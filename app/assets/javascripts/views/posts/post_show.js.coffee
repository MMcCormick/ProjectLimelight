class LL.Views.PostShow extends Backbone.View
  template: JST['posts/show']
  id: 'post-show'
  className: 'content-tile'

  events:
    "click .post-responses input": "showTalkForm"
    "click .close": "navBack"

  initialize: ->
    @responsesCollection = new LL.Collections.PostResponses()
    @responses = new LL.Views.PostShowResponses(collection: @responsesCollection)
    @loaded = null

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

    $(@el).find('.post-responses').append(@responses.el)

    unless @loaded
      @responsesCollection.fetch({data: {id: @model.get('id')}})

    @loaded = true

    view = new LL.Views.PostForm()
    view.placeholder_text = "Post about this #{@model.get('type')}..."
    $(@el).find('.post-responses .top').after(view.render().el)
    i = 1
    for topic in @model.get('topic_mentions')
      view.addTopic($(view.el).find("#post-form-mention#{i}"), topic.get('name'), topic.get('id'))
      break if i == 2
      i++
    view.model.set('parent_id', @model.get('id'))
    $(view.el).find('.icons').remove()

    if LL.App.Feed
      $(@el).addClass('modal')
      $(@el).addClass('modal').append('<div class="close">x</div>')

    @

  showTalkForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    $(@el).find('#post-form').fadeIn(250).find('textarea').focus()

  navBack: (e) =>
    history.back()
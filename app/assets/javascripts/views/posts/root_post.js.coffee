class LL.Views.RootPost extends Backbone.View
  tagName: 'div'
  className: 'tile'
  template: JST['posts/tile']

  events:
    "click .root .img, .talking, h5": "postShow"
    "mouseenter .root": "showHover"
    "mouseenter .reasons": "showReasons"
    "mouseleave .reasons": "hideReasons"
    "click .mentions .delete": "deleteMention"
    "click .mentions .add": "showAddMention"

  initialize: ->
    @responses = null
    @hovering = false
    @opened = false
    @addMentionForm = null

    @model.on('move_to_top', @moveToTop)
    @model.on('new_response', @prependResponse)

  # This renders a root post
  # It adds the root to the top, followed by responses if there are any
  render: ->
    $(@el).addClass(@model.get('root').get('type').toLowerCase())
    switch @model.get('root').get('type')
      when 'Post'
        root_view = new LL.Views.RootTalk(model: @model.get('root'))
      else
        root_view = new LL.Views.RootMedia(model: @model.get('root'))

    $(@el).append(root_view.render().el)

    if @model.get('reasons').length > 0
      reason_div = $('<div/>').addClass('reasons').html("<div class='ll-tan-earmark'></div><ul></ul>")
      first = 'first'
      for reason in @model.get('reasons')
        reason_div.find('ul').append("<li class='#{first}'>#{reason}</li>")
        first = ''
      $(@el).find('.root').append(reason_div)

    @renderResponses()

    @

  postShow: =>
    LL.Router.navigate("posts/#{@model.get('root').get('id')}", trigger: true)

  renderResponses: =>
    if !@responses && @model.get('like_responses').length > 0
      like_responses_view = new LL.Views.RootResponses(model: @model)
      like_responses_view.type = 'like'
      like_responses_view.target = $(@el)
      @responses = like_responses_view

    if !@responses && @model.get('activity_responses').length > 0
      activity_responses_view = new LL.Views.RootResponses(model: @model)
      activity_responses_view.type = 'activity'
      activity_responses_view.target = $(@el)
      @responses = activity_responses_view

    if !@responses && @model.get('feed_responses').length > 0
      feed_responses_view = new LL.Views.FeedReposts(model: @model)
      feed_responses_view.type = 'feed'
      @responses = feed_responses_view

    if @responses
      $(@el).prepend(@responses.render().el)

  moveToTop: =>
    $(@el).html('')
    @render()
    if $(@column.el).offset().top == $(@el).offset().top
      @renderResponses()
    else
      @column.prependPost @

  showHover: (e) =>
    # remove the green background that slowly fades out after a new post is pushed
    $(@el).removeClass('fade-new').find('.root').stop(true, true)

  showReasons: (e) =>
    $(@el).find('.reasons ul').fadeIn(200)

  hideReasons: (e) =>
    $(@el).find('.reasons ul').fadeOut(200)

  deleteMention: (e) =>
    $.ajax '/api/posts/mentions',
      type: 'delete'
      data: {id: @model.get('id'), topic_id: $(e.currentTarget).data('id')}
      beforeSend: ->
        $(e.currentTarget).addClass('disabled')
      success: (data) ->
        $(e.currentTarget).parent().remove()
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.currentTarget).removeClass('disabled')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(e.currentTarget).removeClass('disabled')

  showAddMention: (e) =>
    unless @addMentionForm
      @addMentionForm = new LL.Views.AddMentionForm(model: @model)
      $(e.currentTarget).after(@addMentionForm.render().el)

    $(@addMentionForm.el).fadeToggle(200)

  prependResponse: (post) =>
    console.log 'foo'
    if @responses
      @responses.prependResponse(post)
    else
      @renderResponses()
class LL.Views.RootPost extends Backbone.View
  tagName: 'li'
  className: 'tile'
  template: JST['posts/tile']

  events:
    "click .root .img, .talking, h5": "postShow"
    "mouseenter .root": "showHover"
    "mouseleave .root": "hideHover"
    "mouseenter .reasons": "showReasons"
    "mouseleave .reasons": "hideReasons"
    "click .mentions .delete": "deleteMention"
    "click .mentions .add": "showAddMention"

  initialize: ->
    @feed_responses = null
    @activity_responses = null
    @like_responses = null
    @hovering = false
    @opened = false
    @addMentionForm = null

    @model.get('root').on('new_response', @renderResponses)
    @model.on('move_to_top', @moveToTop)

  # This renders a root post
  # It adds the root to the top, followed by responses if there are any
  render: ->
    if @model.get('root').get('type') == 'Topic'
      mentions = new LL.Views.PostMentions(model: [@model.get('root')])
      $(@el).append(mentions.render().el)
    else
      mentions = new LL.Views.PostMentions(model: @model.get('root').get('topic_mentions'))
      $(@el).append(mentions.render().el)

    $(@el).addClass(@model.get('root').get('type').toLowerCase())
    switch @model.get('root').get('type')
      when 'Talk'
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
    unless @model.get('root').get('type') == 'Topic'
      LL.Router.navigate("posts/#{@model.get('root').get('id')}", trigger: true)

  renderResponses: =>
    hasResponses = false

    if !@like_responses
      like_responses_view = new LL.Views.RootResponses(model: @model)
      like_responses_view.type = 'like'
      like_responses_view.target = $(@el)
      @like_responses = like_responses_view
      if @model.get('like_responses').length > 0
        hasResponses = true
      $(@el).append(@like_responses.render().el)

    if !@activity_responses
      activity_responses_view = new LL.Views.RootResponses(model: @model)
      activity_responses_view.type = 'activity'
      activity_responses_view.target = $(@el)
      @activity_responses = activity_responses_view
      if @model.get('activity_responses').length > 0
        hasResponses = true
      $(@el).append(@activity_responses.render().el)

    if !@feed_responses
      feed_responses_view = new LL.Views.RootResponses(model: @model)
      feed_responses_view.type = 'feed'
      @feed_responses = feed_responses_view
      if @model.get('feed_responses').length > 0
        hasResponses = true
      $(@el).append(@feed_responses.render().el)

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

    return unless $(e.currentTarget).parent().hasClass('tile')

    self = @
    $(@el).oneTime 500, 'post-tile-hover', ->
      $(self.el).find('.bottom-sheet').slideDown 200

  hideHover: (e) =>
    return if $(e.target).hasClass('.bottom-sheet')

    $(@el).stopTime 'post-tile-hover'
    $(@el).find('.bottom-sheet').slideUp 200

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
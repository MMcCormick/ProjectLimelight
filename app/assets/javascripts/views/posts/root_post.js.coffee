class LL.Views.RootPost extends Backbone.View
  tagName: 'li'
  className: 'tile'

  events:
    "click .root .img, .talking, h5": "postShow"
    "mouseenter .root": "showHover"
    "mouseleave .root": "hideHover"
    "mouseenter .reasons": "showReasons"
    "mouseleave .reasons": "hideReasons"

  initialize: ->
    @public_responses = null
    @personal_responses = null
    @activity_responses = null
    @like_responses = null
    @hovering = false
    @opened = false

    @model.get('root').on('new_response', @renderResponses)
    @model.on('move_to_top', @moveToTop)

  # This renders a root post
  # It adds the root to the top, followed by responses if there are any
  render: ->
    if @model.get('root')
      $(@el).addClass(@model.get('root').get('type').toLowerCase())
      switch @model.get('root').get('type')
        when 'Topic'
          root_view = new LL.Views.RootTopic(model: @model.get('root'))
        when 'Talk'
          root_view = new LL.Views.RootTalk(model: @model.get('root'))
        else
          root_view = new LL.Views.RootMedia(model: @model.get('root'))

      $(@el).append(root_view.render().el)

      if @model.get('reasons').length > 0
        reason_div = $('<div/>').addClass('reasons').html("<div class='ll-tan-earmark'></div><ul></ul>")
        for reason in @model.get('reasons')
          reason_div.find('ul').append("<li>#{reason}</li>")
        $(@el).append(reason_div)

    @renderResponses()

    @

  postShow: =>
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

    @like_responses.render()

    if !@activity_responses
      activity_responses_view = new LL.Views.RootResponses(model: @model)
      activity_responses_view.type = 'activity'
      activity_responses_view.target = $(@el)
      @activity_responses = activity_responses_view
      if @model.get('activity_responses').length > 0
        hasResponses = true

    @activity_responses.render()

    if !@personal_responses
      personal_responses_view = new LL.Views.RootResponses(model: @model)
      personal_responses_view.type = 'personal'
      personal_responses_view.target = $(@el)
      @personal_responses = personal_responses_view
      if @model.get('personal_responses').length > 0
        hasResponses = true

    @personal_responses.render()

    if !@public_responses
      public_responses_view = new LL.Views.RootResponses(model: @model)
      public_responses_view.type = 'public'
      public_responses_view.target = $(@el)
      @public_responses = public_responses_view
      if @model.get('public_responses').length > 0
        hasResponses = true

    @public_responses.render()

    if hasResponses == true
      $(@el).find('.root').append("<div class='response-divider'><div class='ll-grey-arrow-up'></div></div>")

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
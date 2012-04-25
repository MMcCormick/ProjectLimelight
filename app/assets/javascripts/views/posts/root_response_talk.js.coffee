class LL.Views.RootResponseTalk extends Backbone.View
  template: JST['posts/root_response_talk']
  tagName: 'div'
  className: 'response-talk'

  events:
    'click': 'postShow'
    "click .comment-form": "commentForm"

  initialize: ->
    @model.on('new_comment', @incrementComment)

  render: ->
    $(@el).html(@template(talk: @model))

    if @model.get('user').get('status') == 'active'
      like = new LL.Views.LikeButton(model: @model)
      $(@el).find('.actions').prepend(like.render().el)

      score = new LL.Views.Score(model: @model)
      $(@el).find('.actions').prepend(score.render().el)

    @

  postShow: (e) =>
    return if $(e.target).is('.ulink, .score-pts, .like, .comment-form') || $(e.target).is('img')
    LL.Router.navigate("talks/#{@model.get('id')}", trigger: true)

  incrementComment: =>
    $(@el).find('.comment-form span').text(parseInt($(@el).find('.comment-form span').text()) + 1)

  commentForm: (e) =>
    self = @
    view = new LL.Views.CommentForm(model: @model)
    view.modal = true
    view.qtip = @el

    $(@el).qtip
      position:
        my: 'top middle'
        at: 'bottom middle'
        viewport: $(window)
      style:
        tip: true
        classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-limelight comment-tip'
      show:
        ready: true
        effect: (offset) ->
          $(@).slideDown(150) # "this" refers to the tooltip
      hide: false
      content:
        text: (api) ->
          $(view.render().el)
      events:
        show: (event,api) ->
          setTimeout ->
            $(event.delegateTarget).find('textarea').focus()
          , 0
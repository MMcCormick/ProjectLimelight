class LL.Views.ResponseTalk extends Backbone.View
  template: JST['posts/response_talk']
  tagName: 'div'
  className: 'response-talk'

  events:
    "click .comment-form": "commentForm"

  initialize: ->

  render: ->
    $(@el).html(@template(talk: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @comments = new LL.Collections.Comments
    @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
    @comments.add(@model.get('comments'))
    $(@el).find('.comments').html(@comments_view.render().el)

    @

  commentForm: (e) =>
    self = @
    view = new LL.Views.CommentForm(model: @model)
    view.modal = true
    view.qtip = $(@el).find('.meat')

    $(@el).find('.meat').qtip
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
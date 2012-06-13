class LL.Views.RootTalk extends Backbone.View
  template: JST['posts/root_talk']
  tagName: 'div'
  className: 'root talk'

  events:
    'click': 'postShow'

  initialize: ->
    @model.on('new_comment', @incrementComment)

  render: ->
    $(@el).html(@template(talk: @model))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @

  postShow: (e) =>
    return if $(e.target).is('a,input,textarea')
#    LL.Router.navigate("talks/#{@model.get('id')}", trigger: true)
#    user_section = new LL.Views.UserSectionList()
#    user_section.users = @model.get('recent_likes')
#    user_section.count = @model.get('likes').length
#    $(@el).find('.half-sections').append(user_section.render().el)

    if $(@el).find('.bottom').is(':visible')
      $(@el).removeClass('open', 200).find('.bottom').slideUp(200)
    else
      if $(@el).find('.comment-list').length == 0
        @comments = new LL.Collections.Comments
        @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
        form = new LL.Views.CommentForm(model: @model)
        form.minimal = true
        $(@el).find('.bottom').append(form.render().el).append(@comments_view.render().el)
        @comments.fetch({data: {id: @model.get('id')}})

      $(@el).addClass('open', 200).find('.bottom').slideDown(200)

  incrementComment: =>
    $(@el).find('.comment-form span').text(parseInt($(@el).find('.comment-form span').text()) + 1)

  commentForm: (e) =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

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
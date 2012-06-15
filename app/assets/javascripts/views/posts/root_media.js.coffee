class LL.Views.RootMedia extends Backbone.View
  template: JST['posts/root_media']
  tagName: 'div'
  className: 'root'

  events:
    "click .talk-form": "loadPostForm"

  initialize: ->

  render: ->
    $(@el).addClass(@model.get('type').toLowerCase()).html(@template(post: @model))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'extended'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @

  loadPostForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    if $(@el).next().attr('id') == 'post-form'
      return

    view = new LL.Views.PostForm()
    view.with_header = false
    view.cancel_buttons = true
    view.placeholder_text = "Repost this #{@model.get('type')} to #{LL.App.current_user.get('followers_count')} followers..."
    view.close_callback = @closePost
    view.preview.show_preview = false
    $(@el).after($(view.render().el).hide())
    view.preview.setResponse(@model)
    $(view.el).find('.icons').remove()
    $(view.el).slideDown(300)

  closePost: (form) =>
    $(form.el).remove();
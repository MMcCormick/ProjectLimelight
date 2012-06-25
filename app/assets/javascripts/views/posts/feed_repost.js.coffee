class LL.Views.FeedRepost extends Backbone.View
  tagName: 'div'
  className: 'repost'
  template: JST['posts/feed_repost']

  events:
    'click': 'postShow'
    "click .repost-btn": "loadPostForm"

  initialize: ->
    @model.on('new_comment', @incrementComment)

  render: ->
    $(@el).html(@template(post: @model.get('post')))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    @

  postShow: (e) =>
    console.log $(e.target)
    return if $(e.target).is('a,h5,input,textarea,.bg,.img,img,.like,.repost-btn')

    self = @

    if $(@el).find('.bottom').is(':visible')
      $(@el).removeClass('open', 200).find('.bottom').slideUp 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).parents('.tile:first').get(0))
    else
      if $(@el).find('.comment-list').length == 0
        @comments = new LL.Collections.Comments
        @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
        form = new LL.Views.CommentForm(model: @model)
        form.minimal = true
        $(@el).find('.bottom').append(form.render().el).append(@comments_view.render().el)
        @comments.fetch({data: {id: @model.get('id')}})

      $(@el).addClass('open', 100).find('.bottom').slideDown 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).parents('.tile:first').get(0))

  incrementComment: =>
    count = $(@el).find('.add-comment span')
    if count.length > 0
      count.text(parseInt(count.text()) + 1)
    else
      $(@el).find('.add-comment').append('<b>(<span>1</span>)</b>')

  loadPostForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    if $(@el).next().attr('id') == 'post-form'
      return

    view = new LL.Views.PostForm()
#    view.with_header = false
    view.cancel_buttons = true
    view.modal = true
    view.placeholder_text = "Repost this #{@model.get('post').get('media').get('type')} to #{LL.App.current_user.get('followers_count')} followers..."
    view.close_callback = @closePost
    view.preview.show_preview = true
#    $(@el).after($(view.render().el).hide())
    view.preview.setResponse(@model.get('post').get('media'))
    view.render()
    $(view.el).find('.icons').remove()
#    $(view.el).slideDown(300)

  closePost: (form) =>
    $(form.el).remove();
class LL.Views.FeedRepost extends Backbone.View
  tagName: 'div'
  className: 'repost'
  template: JST['posts/feed_repost']

  events:
    'click': 'postShow'
    "click .repost-btn": "loadPostForm"

  initialize: ->
    @model.get('post').on('new_comment', @incrementComment)

  render: ->
    $(@el).html(@template(post: @model.get('post')))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('post').get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    mentions = new LL.Views.PostMentions(model: @model.get('post'))
    $(@el).find('.top').append(mentions.render().el)

    like = new LL.Views.LikeButton(model: @model.get('post'))
    $(@el).find('.actions').prepend(like.render().el)

    @

  postShow: (e) =>
    return if $(e.target).is('a,h5,input,textarea,.bg,.img,img,.like,.repost-btn')

    self = @

    if $(@el).find('.bottom').is(':visible')
      $(@el).removeClass('open', 200).find('.bottom').slideUp 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).parents('.tile:first').get(0))
    else
      if $(@el).find('.comment-list').length == 0
        @comments_view = new LL.Views.CommentList(model: @model.get('post'))
        form = new LL.Views.CommentForm(model: @model.get('post'))
        form.minimal = true
        $(@el).find('.bottom').append(form.render().el).append(@comments_view.render().el)
        console.log @model.get('post')
        @model.get('post').fetchComments()

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
    view.cancel_buttons = true
    view.modal = true
    view.with_header = false
    view.close_callback = @closePost
    view.render()
    view.preview.setResponse(@model.get('post').get('media'))
    $(view.el).find('.icons').remove()

  closePost: (form) =>
    $(form.el).remove();
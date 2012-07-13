class LL.Views.FeedRepost extends Backbone.View
  tagName: 'div'
  className: 'repost'
  template: JST['posts/feed_repost']

  events:
    'click': 'postShow'
    "click .repost-btn": "loadPostForm"

  initialize: ->
    @model.get('post').on('new_comment', @incrementComment)
    @img_w = null
    @img_h = null

  render: ->

    if @model.get('post').get('media').get('images') && @model.get('post').get('media').get('images').w >= 300
      @img_w = 300
    else if @model.get('post').get('media').get('images') && @model.get('post').get('media').get('images').w
      @img_w = @model.get('post').get('media').get('images').w

    if @img_w && @model.get('post').get('media').get('images').ratio
      @img_h = @img_w / @model.get('post').get('media').get('images').ratio

    $(@el).html(@template(post: @model.get('post'), img_w: @img_w, img_h: @img_h))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('post').get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    mentions = new LL.Views.PostMentions(model: @model.get('post'))
    $(@el).prepend(mentions.render().el)

    @

  postShow: (e) =>
    return if $(e.target).is('a,h5,input,textarea,.bg,.img,img,.repost-btn')

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
    view.setModel(@model.get('post'))
    view.render()

  closePost: (form) =>
    $(form.el).remove();
class LL.Views.PostShow extends Backbone.View
  template: JST['posts/show']
  id: 'post-show'
  className: 'content-tile'

  events:
    "click .close": "navBack"
    "click .repost-btn": "loadPostForm"
    "click .add-comment": "focusCommentForm"

  initialize: ->
    @responsesCollection = new LL.Collections.PostResponses()
    @responses = new LL.Views.PostShowResponses(collection: @responsesCollection)
    @loaded = null
    @model.on('new_comment', @incrementComment)

  render: =>
    return unless @model
    $(@el).html(@template(post: @model))

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'extended'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').html(prettyTime.render().el)

    topic_section = new LL.Views.TopicSectionList()
    topic_section.topics = @model.get('topic_mentions')
    $(@el).find('.half-sections').append(topic_section.render().el)

    user_section = new LL.Views.UserSectionList()
    user_section.users = @model.get('recent_likes')
    user_section.count = @model.get('likes').length
    $(@el).find('.half-sections').append(user_section.render().el)

    @comments_view = new LL.Views.CommentList(model: @model)
    form = new LL.Views.CommentForm(model: @model)
    form.minimal = true
    $(@el).find('.comments .meat').append(form.render().el).append(@comments_view.render().el)

    if @model.get('comments').length == 0 && !@loaded
      @model.fetchComments()

    @loaded = true

    if LL.App.Feed
      $(@el).addClass('modal')
      $(@el).addClass('modal').append('<div class="close">x</div>')

    @

  focusCommentForm: (e) =>
    $(@el).find('.comment-form textarea').focus()

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
    view.preview.setResponse(@model.get('media'))

  navBack: (e) =>
    history.back()

  incrementComment: =>
    count = $(@el).find('.add-comment span')
    if count.length > 0
      new_count = parseInt(count.text()) + 1
      count.text(new_count)
    else
      new_count = 1
      $(@el).find('.add-comment').append('<b>(<span>1</span>)</b>')

    $(@el).find('.section.comments h4 span').text(new_count)
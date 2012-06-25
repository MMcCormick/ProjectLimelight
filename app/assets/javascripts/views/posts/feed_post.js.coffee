class LL.Views.FeedPost extends Backbone.View
  template: JST['posts/feed_post']
  tagName: 'div'
  className: 'post'

  events:
    'click': 'postShow'

  initialize: ->
    @model.get('post').on('new_comment', @incrementComment)

  render: ->
    $(@el).html(@template(post: @model.get('post')))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('post').get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    mentions = new LL.Views.PostMentions(model: @model.get('post'))
    $(@el).find('.actions').before(mentions.render().el)

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    @

  postShow: (e) =>
    return if $(e.target).is('a,input,textarea,.like')

    self = @

    if $(@el).find('.bottom').is(':visible')
      $(@el).removeClass('open', 200).find('.bottom').slideUp 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).parent().get(0))
    else
      if $(@el).find('.comment-list').length == 0
        @comments_view = new LL.Views.CommentList(model: @model.get('post'))
        form = new LL.Views.CommentForm(model: @model.get('post'))
        form.minimal = true
        $(@el).find('.bottom').append(form.render().el).append(@comments_view.render().el)
        @model.get('post').fetchComments()

      $(@el).addClass('open', 100).find('.bottom').slideDown 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).parent().get(0))

  incrementComment: =>
    count = $(@el).find('.add-comment span')
    if count.length > 0
      count.text(parseInt(count.text()) + 1)
    else
      $(@el).find('.add-comment').append('<b>(<span>1</span>)</b>')
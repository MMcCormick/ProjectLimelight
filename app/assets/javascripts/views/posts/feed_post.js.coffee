class LL.Views.FeedPost extends Backbone.View
  template: JST['posts/feed_post']
  tagName: 'div'
  className: 'post'

  events:
    'click': 'postShow'

  initialize: ->
    @model.on('new_comment', @incrementComment)

  render: ->
    $(@el).html(@template(post: @model))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

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
        @comments = new LL.Collections.Comments
        @comments_view = new LL.Views.CommentList(collection: @comments, model: @model)
        form = new LL.Views.CommentForm(model: @model)
        form.minimal = true
        $(@el).find('.bottom').append(form.render().el).append(@comments_view.render().el)
        @comments.fetch({data: {id: @model.get('id')}})

      $(@el).addClass('open', 100).find('.bottom').slideDown 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).parent().get(0))

  incrementComment: =>
    $(@el).find('.comment-form span').text(parseInt($(@el).find('.comment-form span').text()) + 1)
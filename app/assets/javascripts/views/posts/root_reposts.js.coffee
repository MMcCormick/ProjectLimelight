class LL.Views.FeedReposts extends Backbone.View
  template: JST['posts/root_reposts']
  tagName: 'div'
  className: 'reposts'

  render: =>
    if @type == 'feed'
      reposts = @model.get('feed_responses')
    else if @type == 'like'
      reposts = @model.get('like_responses')
#      className = 'like-responses'
#      talking = ""
    else if @type == 'activity'
      reposts = @model.get('activity_responses')
#      className = 'activity-responses'
#      talking = ""

    $(@el).remove()

    if reposts.length > 0
      $(@el).html(@template(model: @model))

      for post in reposts
        @appendRepost(post)

    @

  appendRepost: (post) =>
    view = new LL.Views.FeedRepost(model: post)
    view.media = @model.get('root')
    $(@el).find('ul').append(view.render().el)

    @

  prependResponse: (post) =>
    view = new LL.Views.FeedRepost(model: post)
    view.media = @model.get('root')
    existing = $(@el).find('ul li:first')
    $(@el).find('ul').prepend($(view.render().el).hide())

    existing.css('float', 'left').hide "slide", { direction: 'right' }, 500, ->
      @remove()

    $(view.el).show("slide", { direction: 'left' }, 500)

    @
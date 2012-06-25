class LL.Views.FeedMediaReposts extends Backbone.View
  tagName: 'div'
  className: 'reposts'

  render: ->
    view = new LL.Views.FeedRepost(model: @model)
    view.media = @model.get('media')
    $(@el).append(view.render().el)

    @
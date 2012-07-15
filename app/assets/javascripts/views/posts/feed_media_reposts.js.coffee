class LL.Views.FeedMediaShares extends Backbone.View
  tagName: 'div'
  className: 'shares'

  render: ->
    view = new LL.Views.FeedShare(model: @model)
    view.media = @model.get('media')
    $(@el).append(view.render().el)

    @
class LL.Views.FeedMedia extends Backbone.View
  template: JST['posts/feed_media']
  tagName: 'div'
  className: 'media'

  initialize: ->

  render: ->
    $(@el).addClass(@model.get('type').toLowerCase()).html(@template(post: @model))

    @
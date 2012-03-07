class LL.Views.UserFeedHeader extends Backbone.View
  template: JST['users/feed_header']
  el: $('#feed')
  id: 'user-feed-header'
  className: 'feed-header'

  initialize: ->
    @model.on('change', @render)
    @loaded = null

  render: =>
    return if @loaded
    @loaded = true

    $(@el).prepend(@template(user: @model))

    # Influence strip
    influences = new LL.Views.UserTopicInfluences(model: @model)
    $(@el).append(influences.render().el)

    @
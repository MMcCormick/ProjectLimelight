class LL.Views.UserFeedHeader extends Backbone.View
  template: JST['users/feed_header']
  el: $('#feed')
  id: 'user-feed-header'
  className: 'feed-header'

  initialize: ->

  render: =>
    $(@el).prepend(@template(user: @model))

    # Influence strip
    influences = new LL.Views.UserTopicInfluences(model: @model)
    $(@el).append(influences.render().el)

    @
class LL.Views.UserLikeHeader extends Backbone.View
  template: JST['users/like_header']
  el: $('#feed')
  id: 'user-like-header'
  className: 'feed-header'

  initialize: ->
    @model.on('change', @render)
    @loaded = null

  render: =>
    return if @loaded
    @loaded = true

    $(@el).prepend(@template(user: @model))

    @
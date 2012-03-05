class LL.Views.UserLikeHeader extends Backbone.View
  template: JST['users/like_header']
  el: $('#feed')
  id: 'user-like-header'
  className: 'feed-header'

  initialize: ->

  render: =>
    $(@el).prepend(@template(user: @model))

    @
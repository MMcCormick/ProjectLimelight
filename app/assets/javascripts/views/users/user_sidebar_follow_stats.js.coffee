class LL.Views.UserSidebarFollowStats extends Backbone.View
  template: JST['users/sidebar_follow_stats']
  className: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    @
class LL.Views.UserSidebarFollowStats extends Backbone.View
  template: JST['users/sidebar_follow_stats']
  tagName: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    @
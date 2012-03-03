class LL.Views.UserSidebarNav extends Backbone.View
  template: JST['users/sidebar_nav']
  tagName: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    if LL.App.current_user != @model
      follow = new LL.Views.FollowButton(model: @model)
      $(@el).find('.score-pts').before(follow.render().el)

    @
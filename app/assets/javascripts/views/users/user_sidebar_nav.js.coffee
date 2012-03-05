class LL.Views.UserSidebarNav extends Backbone.View
  template: JST['users/sidebar_nav']
  tagName: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').append(score.render().el)

    if LL.App.current_user != @model
      follow = new LL.Views.FollowButton(model: @model)
      $(@el).find('.actions').prepend(follow.render().el)

    @
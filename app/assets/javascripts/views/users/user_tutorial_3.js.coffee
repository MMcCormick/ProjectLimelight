class LL.Views.UserTutorial3 extends Backbone.View
  template: JST['users/tutorial_3']
  className: 'tutorial-section'
  id: 'tutorial-3'

  initialize: ->
    @title= 'Invite Friends (you can always do this after the tutorial)'

  render: ->
    $(@el).html(@template(user: @model))

    view = new LL.Views.UserInviteOptions(model: @model)
    $(@el).append(view.render().el)

    @
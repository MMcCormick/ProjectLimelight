class LL.Views.UserTutorial4 extends Backbone.View
  template: JST['users/tutorial_4']
  className: 'tutorial-section'
  id: 'tutorial-4'

  initialize: ->
    @title= 'Invite Friends!'

  render: ->
    $(@el).html(@template(user: @model))
    @
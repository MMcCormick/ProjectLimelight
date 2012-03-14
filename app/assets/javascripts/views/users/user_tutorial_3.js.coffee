class LL.Views.UserTutorial3 extends Backbone.View
  template: JST['users/tutorial_3']
  className: 'tutorial-section'
  id: 'tutorial-3'

  initialize: ->
    @title= 'Posting on Limelight'

  render: ->
    $(@el).html(@template(user: @model))
    @
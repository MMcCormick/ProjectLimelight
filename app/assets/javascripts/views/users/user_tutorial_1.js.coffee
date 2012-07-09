class LL.Views.UserTutorial1 extends Backbone.View
  template: JST['users/tutorial_1']
  className: 'tutorial-section'
  id: 'tutorial-1'

  initialize: ->
    @title = 'Connect Existing Social Networks'

  render: ->
    $(@el).html(@template(user: @model))

    settings = new LL.Views.SocialSettings(model: @model)
    $(@el).append(settings.render().el)

    @
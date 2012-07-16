class LL.Views.UserTutorial4 extends Backbone.View
  className: 'tutorial-section'
  id: 'tutorial-4'

  initialize: ->
    @title= 'The +Share Button'

  render: ->
    view = new LL.Views.BookmarkletIntro()
    $(@el).append(view.render().el)

    @
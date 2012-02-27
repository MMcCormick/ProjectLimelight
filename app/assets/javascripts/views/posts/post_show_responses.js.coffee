class LL.Views.PostShowResponses extends Backbone.View
  template: JST['posts/show_responses']
  className: 'section'

  initialize: ->

  render: ->
    $(@el).html(@template())
    @
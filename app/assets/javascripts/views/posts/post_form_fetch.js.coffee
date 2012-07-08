class LL.Views.PostFormFetch extends Backbone.View
  template: JST['posts/form_fetch']

  initialize: ->

  render: =>
    $(@el).html(@template())

    @
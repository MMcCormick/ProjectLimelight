class LL.Views.PostFormFetch extends Backbone.View
  template: JST['posts/form_fetch']

  initialize: ->
    @bookmarklet = false

  render: =>
    $(@el).html(@template(bookmarklet: @bookmarklet))

    @
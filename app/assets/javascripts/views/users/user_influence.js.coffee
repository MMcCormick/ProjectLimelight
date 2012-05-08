class LL.Views.UserInfluence extends Backbone.View
  template: JST['users/influence']
  el: '#feed'
  id: 'user-influence-page'

  initialize: =>
    @collection.on('reset', @render)

  render: =>
    $(@el).html(@template())

    @
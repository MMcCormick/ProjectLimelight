class LL.Views.SplashInfluenceIncrease extends Backbone.View
  template: JST['splash_influence_increase']
  tagName: 'li'

  initialize: ->

  render: =>
    $(@el).html(@template(influence: @model)).hide()

    @
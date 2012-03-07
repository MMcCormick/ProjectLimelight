class LL.Views.InfluenceIncrease extends Backbone.View
  template: JST['users/influence_increase']
  tagName: 'li'

  initialize: ->

  render: =>
    console.log @model
    $(@el).html(@template(influence: @model))

    @
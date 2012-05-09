class LL.Views.InfluenceIncreaseFull extends Backbone.View
  template: JST['users/influence_increase_full']
  tagName: 'li'

  events:
    'click .plink': 'showPost'

  initialize: ->

  render: =>
    $(@el).html(@template(influence: @model))

    @

  showPost: =>
    LL.Router.navigate("talks/#{@model.get('post').id}", trigger: true)
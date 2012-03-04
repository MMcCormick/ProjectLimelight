class LL.Views.Score extends Backbone.View
  template: JST['widgets/score']
  className: 'score-pts'
  tagName: 'span'

  initialize: ->
    self = @
    channel = pusher.subscribe(@model.get('_id'));
    channel.bind 'score_change', (data) ->
      self.model.set('score', self.model.get('score') + data.change)
      self.render()

  render: =>
    $(@el).html(@template(model: @model))
    @
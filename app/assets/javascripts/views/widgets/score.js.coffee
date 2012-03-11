class LL.Views.Score extends Backbone.View
  template: JST['widgets/score']
  className: 'score-pts'
  tagName: 'span'

  initialize: ->
    self = @

    channel = LL.App.get_subscription(@model.get('_id'))
    unless channel
      channel = LL.App.subscribe(@model.get('_id'))

    unless LL.App.get_event_subscription(@model.get('_id'), 'score_change')
      channel.bind 'score_change', (data) ->
        self.model.set('score', self.model.get('score') + data.change)
        self.render()
      LL.App.subscribe_event(@model.get('_id'), 'score_change')

  render: =>
    $(@el).html(@template(model: @model))
    @
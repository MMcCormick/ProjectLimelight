class LL.Views.PrettyTime extends Backbone.View
  template: JST['widgets/pretty_time']
  className: 'pretty-time'
  tagName: 'span'

  initialize: ->
    self = @
    $(@el).everyTime 60000, 'update-time', ->
      self.render()

  render: =>
    $(@el).html(humaneDate(new Date(@time*1000), null, if @format == 'extended' then 0 else 1))
    @
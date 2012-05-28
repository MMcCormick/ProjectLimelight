class LL.Models.InfluenceIncrease extends Backbone.Model
  keepInSync: true
  name: 'influence-increase'

  initialize: =>
    if @get('user')
      @set('user', new LL.Models.User(@get('user')))
    if @get('triggered_by')
      @set('triggered_by', new LL.Models.User(@get('triggered_by')))
    if @get('topic')
      @set('topic', new LL.Models.Topic(@get('topic')))
    if @get('post')
      @set('post', new LL.Models.Post(@get('post')))
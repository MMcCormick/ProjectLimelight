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

#  parse: (resp, xhr) ->
#    data = {
#      'topic_id': resp.id
#      'amount': resp.amount
#      'reason': resp.reason
#      'action': resp.action
#      'created_at_pretty': resp.created_at_pretty
#    }
#
#    data['topic'] = new LL.Models.Topic(resp.topic.id, resp.topic)
#    data['user'] = new LL.Models.User(resp.user.id, resp.user)
#    data['triggered_by'] = new LL.Models.User(resp.triggered_by)
#    data['post'] = new LL.Models.Post(resp.post)
#
#    data
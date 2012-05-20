class LL.Models.InfluenceIncrease extends Backbone.Model

  initialize: =>
    if @get('user')
      @set('user', LL.App.Users.findOrCreate(@get('user').id, @get('user')))
    if @get('triggered_by')
      @set('triggered_by', LL.App.Users.findOrCreate(@get('triggered_by').id, @get('triggered_by')))
    if @get('topic')
      @set('topic', LL.App.Topics.findOrCreate(@get('topic').id, @get('topic')))
    if @get('post')
      @set('post', LL.App.Posts.findOrCreate(@get('post').id, @get('post')))

  parse: (resp, xhr) ->
    data = {
      'topic_id': resp.id
      'amount': resp.amount
      'reason': resp.reason
      'action': resp.action
      'created_at_pretty': resp.created_at_pretty
    }

    data['topic'] = new LL.Models.Topic(resp.topic)
    data['user'] = new LL.Models.User(resp.user)
    data['triggered_by'] = new LL.Models.User(resp.triggered_by)
    data['post'] = new LL.Models.Post(resp.post)

    data
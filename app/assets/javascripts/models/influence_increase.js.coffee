class LL.Models.InfluenceIncrease extends Backbone.Model

  parse: (resp, xhr) ->
    data = {
      'amount': resp.amount
      'topic_id': resp.topic_id
    }

    data['topic'] = LL.App.Topics.findOrCreate(resp.topic.id, new LL.Models.Topic(resp.topic))

    data
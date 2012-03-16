class LL.Models.InfluenceIncrease extends Backbone.Model

  parse: (resp, xhr) ->
    data = {
      'topic_id': resp.id
      'amount': resp.amount
      'reason': resp.reason
    }

    data['topic'] = new LL.Models.Topic(resp.topic)

    data
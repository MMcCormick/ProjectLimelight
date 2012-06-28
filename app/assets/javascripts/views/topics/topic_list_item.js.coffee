class LL.Views.TopicListItem extends Backbone.View
  template: JST['topics/list_item']
  tagName: 'li'

  initialize: ->

  render: =>
    $(@el).addClass('odd') if @odd
    $(@el).append(@template(topic: @model))

    follow = new LL.Views.FollowButton(model: @model)
    $(@el).find('.follow-c').html(follow.render().el)

#    score = new LL.Views.Score(model: @model)
#    $(@el).append(score.render().el)

    @
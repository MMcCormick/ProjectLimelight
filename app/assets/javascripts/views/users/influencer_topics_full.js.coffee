class LL.Views.InfluencerTopicsFull extends Backbone.View
  tagName: 'ul'
  id: 'influencer-topics-full'
  className: 'unstyled'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    self = @

    if @collection.models.length == 0
      $(@el).html('<li class="none">This section updates as you gain influence in topics</li>')

    for influencer_topic in @collection.models
      @appendTopic(influencer_topic)

    $(@el).find('li').last().addClass('last')

    @

  appendTopic: (influencer_topic) =>
    view = new LL.Views.InfluencerTopicFull(model: influencer_topic)
    $(@el).find('.none').remove()
    $(@el).append($(view.render().el))
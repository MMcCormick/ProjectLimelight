class LL.Views.AlmostInfluencerTopicsFull extends Backbone.View
  tagName: 'ul'
  id: 'almost-influencer-topics-full'
  className: 'unstyled'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    self = @

    if @collection.models.length == 0
      $(@el).html('<li class="none">This section updates as you gain influence in topics</li>')

    for almost_influencer_topic in @collection.models
      @appendTopic(almost_influencer_topic)

    $(@el).find('li').last().addClass('last')

    @

  appendTopic: (almost_influencer_topic) =>
    view = new LL.Views.AlmostInfluencerTopicFull(model: almost_influencer_topic)
    $(@el).find('.none').remove()
    $(@el).append($(view.render().el))
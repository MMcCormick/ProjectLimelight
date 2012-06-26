class LL.Views.FeedTopicRibbonItem extends Backbone.View
  template: JST['posts/topic_ribbon_item']
  tagName: 'li'

  initialize: ->
    self = @

  render: =>
    $(@el).addClass("ribbon-#{@item.get('topic').get('url_pretty')}").html(@template(on: false, type: @type, model: @model, item: @item))

    @
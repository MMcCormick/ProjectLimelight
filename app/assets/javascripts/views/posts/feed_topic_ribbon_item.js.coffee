class LL.Views.FeedTopicRibbonItem extends Backbone.View
  template: JST['posts/topic_ribbon_item']
  tagName: 'li'

  initialize: ->
    self = @

  render: =>
    image = @item.get('topic').get('images').square.normal
    $(@el).addClass("ribbon-#{@item.get('topic').get('url_pretty')}").html(@template(type: @type, model: @model, item: @item, image: image))

    @
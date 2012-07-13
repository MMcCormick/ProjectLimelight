class LL.Views.FeedTopicRibbonItem extends Backbone.View
  template: JST['posts/topic_ribbon_item']
  tagName: 'li'

  initialize: ->
    self = @

  render: =>
    image = @item.get('topic').get('images').square.normal

    @base = 'Post'
    if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id')
      @url = "/activity#{@item.get('topic').get('url')}"
    else
      @url = "#{@model.get('url')}#{@item.get('topic').get('url')}"

    $(@el).addClass("ribbon-#{@item.get('topic').get('url_pretty')}").html(@template(base: @base, url: @url, model: @model, item: @item, image: image))

    @
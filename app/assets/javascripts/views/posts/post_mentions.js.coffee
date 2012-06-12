class LL.Views.PostMentions extends Backbone.View
  tagName: 'div'
  className: 'mentions'
  template: JST['posts/mentions']

  render: ->
    if @model
      $(@el).html(@template(mentions: @model))

    @
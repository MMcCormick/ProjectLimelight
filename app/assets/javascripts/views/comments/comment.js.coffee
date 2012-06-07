class LL.Views.Comment extends Backbone.View
  template: JST['comments/comment']
  class: 'comment-list'
  tagName: 'li'

  initialize: ->

  render: ->
    $(@el).html(@template(comment: @model))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'short'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').append(prettyTime.render().el)

    @
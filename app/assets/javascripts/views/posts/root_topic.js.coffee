class LL.Views.RootTopic extends Backbone.View
  template: JST['posts/root_topic']
  tagName: 'div'
  className: 'root topic'

  events:
    "click .talk-form": "loadPostForm"

  initialize: ->

  render: ->
    $(@el).html(@template(topic: @model))

    follow = new LL.Views.FollowButton(model: @model)
    $(@el).find('.actions').prepend(follow.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.modal = true
    view.placeholder_text = "Talk about #{@model.get('name')}..."
    view.render().el
    view.addTopic($(view.el).find('#post-form-mention1'), @model.get('name'), @model.get('id'), @model.get('id'))
    $(view.el).find('.icons').remove()
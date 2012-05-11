class LL.Views.TopicSidebarNav extends Backbone.View
  template: JST['topics/sidebar_nav']
  tagName: 'section'

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->

  render: ->
    console.log @model
    $(@el).html(@template(topic: @model))

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').append(score.render().el)

    follow = new LL.Views.FollowButton(model: @model)
    $(@el).find('.actions').prepend(follow.render().el)

    @

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()
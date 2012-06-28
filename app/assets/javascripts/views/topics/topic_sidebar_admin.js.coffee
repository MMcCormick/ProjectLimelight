class LL.Views.TopicSidebarAdmin extends Backbone.View
  template: JST['topics/sidebar_admin']
  tagName: 'div'
  className: 'section'

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->

  render: ->
    $(@el).html(@template(topic: @model))

    destroy = new LL.Views.TopicDestroyButton(model: @model)
    $(@el).find('.edit-btn').after(destroy.render().el)

    @

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()
class LL.Views.PostForm extends Backbone.View
  template: JST['posts/form']
  id: 'post-form'

  events:
      "submit form": "createPost"
      "click .bg": "destroyForm"
      "click .cancel": "destroyForm"

  initialize: ->
    @collection = new LL.Collections.Posts()

  render: ->
    $(@el).html(@template())
    @

  createPost: (e) ->
    e.preventDefault()

    attributes = {}
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    @collection.create attributes,
      wait: true
      success: ->
        self.destroyForm()
      error: @handleError

  handleError: (entry, response) ->
    if response.status == 422
      errors = $.parseJSON(response.responseText).errors
      for attribute, messages of errors
        alert "#{attribute} #{message}" for message in messages

  destroyForm: ->
    $(@el).remove()
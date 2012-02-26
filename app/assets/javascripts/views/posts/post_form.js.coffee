class LL.Views.PostForm extends Backbone.View
  template: JST['posts/form']
  id: 'post-form'

  events:
      "submit form": "createPost"
      "click .bg": "destroyForm"
      "click .cancel": "destroyForm"
      "paste #post-form-fetch-url": "fetchEmbedly"

  initialize: ->
    @collection = new LL.Collections.Posts()

    @model = new LL.Models.PostForm()
    @model.on('change', @updateFields)

    @embedly_collection = new LL.Collections.Embedly
    @embedly = new LL.Views.PostFormPreview({collection: @embedly_collection, post_form: @model})
    @embedly.post_form = @model

  render: ->
    $('body').append($(@el).html(@template()))
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

  updateFields: =>
    $(@el).find('#post-form-type').val(@model.get('type'))
    $(@el).find('#post-form-source-url').val(@model.get('source_url'))
    $(@el).find('#post-form-source-name').val(@model.get('provider_name'))
    $(@el).find('#post-form-source-vid').val(@model.get('source_vid'))
    $(@el).find('#post-form-embed').val(@model.get('embed'))
    $(@el).find('#post-form-parent-id').val(@model.get('parent_id'))
    $(@el).find('#post-form-remote-image-url').val(@model.get('remote_image_url'))
    $(@el).find('#post-form-image-cache').val(@model.get('image_cache'))

  fetchEmbedly: ->
    self = @

    # Need to use a timeout to wait until the paste content is in the input
    setTimeout ->
      self.embedly_collection.fetch({data: {url: self.embedly.target.val()}})
    , 0
class LL.Views.PostForm extends Backbone.View
  template: JST['posts/form']
  id: 'post-form'
  className: 'modal fade'

  events:
      "submit form": "createPost"
      "click .cancel": "destroyForm"
      "paste #post-form-fetch-url": "fetchEmbedly"
      "click .icons .icon:not(.cancel-preview)": "activateType"
      "click .icons .cancel-preview": "removeEmbedly"

  initialize: ->
    @collection = new LL.Collections.Posts()

    @model = new LL.Models.PostForm()
    @model.on('change', @updateFields)
    @model.on('change:type', @updateType)

    @embedly_collection = new LL.Collections.Embedly
    @preview = new LL.Views.PostFormPreview({collection: @embedly_collection, post_form_model: @model})
    @preview.post_form_model = @model

  render: ->
    $(@el).html(@template())
    @preview.target = $(@el).find('#post-form-fetch-url')
    $(@el).modal()

    # setTimeout to wait for the modal animation so that the autocomplete can position itself correctly
    self = @
    setTimeout ->
      $(self.el).find('input.topic-mention').each (i,val) ->
        $(val).soulmate
          url:            '/autocomplete/search',
          types:          ['topic'],
          minQueryLength: 2,
          maxResults:     10,
          allowNew:       true,
          selectFirst:    true,
          renderCallback: (term, data, type) ->
            term
          selectCallback: (term, data, type) ->
            $(val).val(data.term).next().val(data.id)
    , 1200

    @

  createPost: (e) ->
    e.preventDefault()

    attributes = {}
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    @collection.create attributes,
      wait: true
      success: (post) ->
        self.destroyForm()
      error: @handleError

  handleError: (entry, response) ->
    if response.status == 422
      errors = $.parseJSON(response.responseText).errors
      for attribute, messages of errors
        alert "#{attribute} #{message}" for message in messages

  destroyForm: ->
    $(@el).modal('hide')

  updateFields: =>

    $(@el).find('#post-form-source-url').val(@model.get('source_url'))
    $(@el).find('#post-form-source-name').val(@model.get('provider_name'))
    $(@el).find('#post-form-source-vid').val(@model.get('source_vid'))
    $(@el).find('#post-form-embed').val(@model.get('embed'))
    $(@el).find('#post-form-parent-id').val(@model.get('parent_id'))
    $(@el).find('#post-form-remote-image-url').val(@model.get('remote_image_url'))
    $(@el).find('#post-form-image-cache').val(@model.get('image_cache'))

  updateType: =>
    $(@el).find('#post-form-type').val(@model.get('type'))
    $(@el).find('.icons .icon').removeClass('on')

    if @model.get('type') == 'Talk' && !@model.get('parent_id')
      $(@el).find('.icons').removeClass('on').find('.cancel-preview').hide()
      $(@el).find('#post-form-fetch-url').hide().val('')
    else
      $(@el).find('.icons .cancel-preview').show()
      switch @model.get('type')
        when 'Link'
          flag = true
          $(@el).find('.ll-icon-link').addClass('on')
        when 'Picture'
          flag = true
          $(@el).find('.ll-icon-picture').addClass('on')
        when 'Video'
          flag = true
          $(@el).find('.ll-icon-video').addClass('on')

  activateType: (e) =>
    # if we have not started a preview
    if $(@el).find('#post-form-fetch-url:visible,.preview-data').length == 0
      $(@el).find('#post-form-fetch-url').show()

    @model.set('type', $(e.target).data('type'))

  removeEmbedly: =>
    @preview.cancelPreview()

  fetchEmbedly: =>
    self = @

    # Need to use a timeout to wait until the paste content is in the input
    setTimeout ->
      self.embedly_collection.fetch({data: {url: self.preview.target.val()}})
    , 0
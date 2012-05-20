class LL.Views.TopicSlugForm extends Backbone.View
  # Note: the endpoint doesn't correctly / locking slugs is not implemented
  template: JST['topics/slug_form']
  tagName: 'div'
  className: 'section'
  id: 'topic-slug-form'

  events:
    'click .btn-success': 'lockSlug'

  initialize: ->

  render: =>
    $(@el).html(@template(topic: @model))

    @

  lockSlug: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {id: @model.get('id')}
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    $.ajax '/api/topics/lock_slug',
      type: 'put'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        createGrowl false, "Topic updated", 'Success', 'green'
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
class LL.Views.TopicFreebaseForm extends Backbone.View
  template: JST['topics/freebase_form']
  tagName: 'div'
  className: 'section'
  id: 'topic-freebase-form'

  events:
    'click .btn-success': 'updateFreebase'
    'click .delete': 'removeFreebase'

  initialize: ->

  render: =>
    $(@el).html(@template(topic: @model))
    @

  updateFreebase: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {
      freebase_mid: $(@el).find('.freebase-mid').val()
    }
    for input in $(@el).find('input[type="checkbox"]')
      attributes[$(input).attr('name')] = $(input).val() if $(input).is(':checked')

    self = @
    $.ajax "/api/topics/#{@model.get('id')}/freebase",
      type: 'put'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Connect')
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Connect')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Connect')

  removeFreebase: (e) =>
    return if $(e.target).hasClass('disabled')

    e.preventDefault()

    self = @
    $.ajax "/api/topics/#{@model.get('id')}/freebase",
      type: 'delete'
      beforeSend: ->
        $(e.target).addClass('disabled').text('Deleting...')
      success: (data) ->
        $(e.currentTarget).parent().remove()
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.currentTarget).removeClass('disabled').text('[delete]')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(e.target).removeClass('disabled').text('[delete]')
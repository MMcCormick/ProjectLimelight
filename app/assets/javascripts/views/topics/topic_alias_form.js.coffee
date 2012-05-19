class LL.Views.TopicAliasForm extends Backbone.View
  template: JST['topics/alias_form']
  tagName: 'div'
  className: 'section'
  id: 'topic-alias-form'

  events:
    'click .btn-success': 'addAlias'
    'click .delete': 'removeAlias'
    'click .ooac-btn': 'updateAlias'

  initialize: ->

  render: =>
    $(@el).html(@template(topic: @model))

    @

  addAlias: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {id: @model.get('id')}
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()
    for input in $(@el).find('input[type="checkbox"]')
      attributes[$(input).attr('name')] = $(input).val() if $(input).is(':checked')

    self = @
    $.ajax '/api/topics/aliases',
      type: 'post'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Alias')
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Alias')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Alias')

  removeAlias: (e) =>
    return if $(e.target).hasClass('disabled')

    e.preventDefault()

    attributes = {id: @model.get('id'), name: $(e.target).prev('.name').text()}

    self = @
    $.ajax '/api/topics/aliases',
      type: 'delete'
      data: attributes
      beforeSend: ->
        $(e.target).addClass('disabled').text('Submitting...')
      success: (data) ->
        $(e.target).parent().remove()
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.target).removeClass('disabled').text('delete')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(e.target).removeClass('disabled').text('delete')

  updateAlias: (e) =>
    return if $(e.target).hasClass('disabled')

    e.preventDefault()

    attributes = {id: @model.get('id'), alias_id: $(e.target).data('id'), name: $(e.target).prev('.name').text(), ooac: $(e.target).data('val') }

    self = @
    $.ajax '/api/topics/aliases',
      type: 'put'
      data: attributes
      beforeSend: ->
        $(e.target).addClass('disabled').text('Submitting...')
      success: (data) ->
        $(e.target).text('[updated!]')
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.target).text('[fail whale]')
        globalError(jqXHR, $(self.el))
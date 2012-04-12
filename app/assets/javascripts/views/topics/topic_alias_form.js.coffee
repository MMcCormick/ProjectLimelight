class LL.Views.TopicAliasForm extends Backbone.View
  template: JST['topics/alias_form']
  tagName: 'section'
  id: 'topic-alias-form'

  events:
    'click .btn-success': 'addAlias'

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
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
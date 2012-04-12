class LL.Views.TopicBasicForm extends Backbone.View
  template: JST['topics/basic_form']
  tagName: 'section'
  id: 'topic-basic-form'

  events:
    'click .btn-success': 'updateTopic'

  initialize: ->

  render: =>
    $(@el).html(@template(topic: @model))

    @

  updateTopic: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {id: @model.get('id')}
    for input in $(@el).find('textarea, input[type="text"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    $.ajax '/api/topics',
      type: 'put'
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
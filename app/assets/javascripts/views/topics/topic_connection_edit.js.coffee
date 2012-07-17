class LL.Views.TopicConnectionEdit extends Backbone.View
  template: JST['topics/connection_edit']
  tagName: 'li'
  className: 'topic-connection'

  events:
    'click .delete': 'deleteConnection'
    'click .primary': 'makePrimary'

  initialize: ->

  render: =>
    $(@el).html(@template(connection: @model, topic: @topic))

    @

  deleteConnection: (e) =>
    return if $(@el).find('.delete').hasClass('disabled')

    e.preventDefault()

    attributes = { topic1_id: @topic.get('id'), topic2_id: @model.uuid, connection_id: @connection_id }

    self = @
    $.ajax '/api/topics/connections',
      type: 'delete'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        createGrowl false, "Topic updated", 'Success', 'green'
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')

  makePrimary: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    e.preventDefault()

    attributes = { id: @topic.get('id') }

    if $(e.currentTarget).hasClass('on')
      attributes['primary_type_id'] = 0
    else
      attributes['primary_type_id'] = @model.uuid

    self = @
    $.ajax '/api/topics',
      type: 'put'
      data: attributes
      beforeSend: ->
        $(e.currentTarget).addClass('disabled').text('Submitting...')
      success: (data) ->
        createGrowl false, "Topic updated", 'Success', 'green'
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.currentTarget).removeClass('disabled').text('make primary')
        globalError(textStatus, $(self.el))
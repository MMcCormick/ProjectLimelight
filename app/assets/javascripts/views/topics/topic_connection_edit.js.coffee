class LL.Views.TopicConnectionEdit extends Backbone.View
  template: JST['topics/connection_edit']
  tagName: 'li'
  className: 'topic-connection'

  events:
    'click .delete': 'deleteConnection'
    'click .pull.on': 'deleteConnection'
    'click .push.on': 'deleteConnection'
    'click .pull.off': 'addConnection'
    'click .push.off': 'addConnection'
    'click .primary': 'makePrimary'

  initialize: ->

  render: =>
    $(@el).html(@template(connection: @model, topic: @topic, connection_id: @connection_id))

    @

  deleteConnection: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    e.preventDefault()

    if $(e.currentTarget).hasClass('delete')
      attributes = { topic1_id: @topic.get('id'), topic2_id: @model.uuid, id: @connection_id }
    else if $(e.currentTarget).hasClass('push')
      attributes = { topic1_id: @model.uuid, topic2_id: @topic.get('id'), id: 'pull' }
    else
      attributes = { topic1_id: @topic.get('id'), topic2_id: @model.uuid, id: 'pull' }

    self = @
    $.ajax '/api/topics/connections',
      type: 'delete'
      data: attributes
      beforeSend: ->
        $(e.currentTarget).addClass('disabled').text('Submitting...')
      success: (data) ->
        $(e.currentTarget).text('updated')
        createGrowl false, "Topic updated", 'Success', 'green'
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        globalError(textStatus, $(self.el))

  addConnection: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    e.preventDefault()

    if $(e.currentTarget).hasClass('push')
      attributes = { topic1_id: @model.uuid, topic2_id: @topic.get('id'), id: 'pull' }
    else
      attributes = { topic1_id: @topic.get('id'), topic2_id: @model.uuid, id: 'pull' }

    self = @
    $.ajax '/api/topics/connections',
      type: 'post'
      data: attributes
      beforeSend: ->
        $(e.currentTarget).addClass('disabled').text('Submitting...')
      success: (data) ->
        $(e.currentTarget).text('updated')
        createGrowl false, "Topic updated", 'Success', 'green'
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        globalError(textStatus, $(self.el))

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
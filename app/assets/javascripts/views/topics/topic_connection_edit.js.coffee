class LL.Views.TopicConnectionEdit extends Backbone.View
  template: JST['topics/connection_edit']
  tagName: 'li'
  className: 'topic-connection'

  events:
    'click .delete': 'deleteConnection'

  initialize: ->

  render: =>
    $(@el).html(@template(connection: @model))

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
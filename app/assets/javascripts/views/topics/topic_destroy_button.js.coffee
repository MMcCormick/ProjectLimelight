class LL.Views.TopicDestroyButton extends Backbone.View
  template: JST['topics/destroy_button']
  className: 'destroy btn btn-danger'
  tagName: 'span'

  events:
    'click': 'destroyTopic'

  initialize: ->

  render: =>

    if LL.App.current_user && LL.App.current_user.hasRole('admin')
      $(@el).html(@template(model: @model))

    @

  destroyTopic: =>
    return if $(@el).hasClass('disabled')

    self = @

    r = confirm("Are you sure you want to permanently destroy the '#{@model.get('name')}' topic?!")
    if r == true

      $.ajax '/api/topics',
        {
          type: 'delete'
          data: {id: self.model.get('id')}
          dataType: 'json'
          beforeSend: ->
            $(self.el).addClass('disabled')
          success: (data) ->
            globalSuccess(data)
            $(self.el).remove()
          error: (jqXHR, textStatus, errorThrown) ->
            $(self.el).removeClass('disabled')
            globalError(jqXHR)
          complete: ->
            $(self.el).removeClass('disabled')
        }
class LL.Views.LikeButton extends Backbone.View
  template: JST['buttons/like']
  className: 'like'
  tagName: 'span'

  events:
    'click': 'updateLike'

  initialize: ->
    @model.bind('change:liked', @render)

  render: =>
    $(@el).html(@template(model: @model))

    @

  updateLike: =>
    return if $(@el).hasClass('disabled')

    self = @

    options = {
      data: {id: @model.get('_id')}
      dataType: 'json'
      beforeSend: ->
        $(self.el).addClass('disabled')
      success: (data) ->
        self.model.set('liked', !self.model.get('liked'))
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).removeClass('disabled')
        globalError(jqXHR)
      complete: ->
        $(self.el).removeClass('disabled')
    }

    if @model.get('liked') == true
      options['type'] = 'delete'
    else
      options['type'] = 'post'

    $.ajax '/api/likes', options
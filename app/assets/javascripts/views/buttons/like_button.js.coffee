class LL.Views.LikeButton extends Backbone.View
  template: JST['buttons/like']
  className: 'like'
  tagName: 'span'

  events:
    'click': 'updateLike'

  initialize: ->
    @model.bind('change:liked', @render)

  render: =>
    console.log @model
    $(@el).html(@template(model: @model))

    @

  updateLike: =>
    return if $(@el).hasClass('disabled')

    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    self = @

    options = {
      data: {id: @model.get('id')}
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
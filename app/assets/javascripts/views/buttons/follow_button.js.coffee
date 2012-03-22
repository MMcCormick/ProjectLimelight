class LL.Views.FollowButton extends Backbone.View
  template: JST['buttons/follow']
  className: 'follow btn btn-success'
  tagName: 'span'

  events:
    'click': 'updateFollow'

  initialize: ->
    unless @model.get('following')
      @model.set('following', LL.App.current_user.following(@model))

    @model.bind('change:following', @render)

  render: =>
    $(@el).html(@template(model: @model))

    @

  updateFollow: =>
    return if $(@el).hasClass('disabled')

    self = @

    options = {
      data: {id: @model.get('_id')}
      dataType: 'json'
      beforeSend: ->
        $(self.el).addClass('disabled')
      success: (data) ->
        self.model.set('following', !self.model.get('following'))
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).removeClass('disabled')
        globalError(jqXHR)
      complete: ->
        $(self.el).removeClass('disabled')
    }

    if @model.get('type') == 'User'
      url = '/api/users/follows'
    else
      url = '/api/topics/follows'

    if @model.get('following') == true
      options['type'] = 'delete'
    else
      options['type'] = 'post'

    $.ajax url, options


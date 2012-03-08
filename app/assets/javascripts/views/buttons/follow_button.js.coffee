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
    self = @

    options = {
      data: {id: @model.get('_id')}
      dataType: 'json'
      beforeSend: ->
        $(self.el).attr('disabled', 'disabled')
      success: (data) ->
        self.model.set('following', !self.model.get('following'))
      complete: ->
        $(self.el).removeAttr('disabled')
    }

    if @model.constructor.name == 'User'
      url = '/api/users/follows'
    else
      url = '/api/topics/follows'

    if @model.get('following') == true
      options['type'] = 'delete'
    else
      options['type'] = 'post'

    $.ajax url, options


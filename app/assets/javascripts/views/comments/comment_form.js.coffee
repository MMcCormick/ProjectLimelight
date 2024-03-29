class LL.Views.CommentForm extends Backbone.View
  template: JST['comments/form']
  className: 'comment-form'

  events:
      "click .submit": "createComment"
      "click .close,.cancel": "destroyForm"
      "click textarea": "requireLogin"
      "keydown textarea": "catchEnter"

  initialize: ->
    @collection = new LL.Collections.Comments()
    @modal = false
    @minimal = false

  render: ->
    $(@el).html(@template(model: @model, modal: @modal, minimal: @minimal))
    $(@el).updatePolyfill()
    @

  createComment: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {}
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()

    self = @
    @collection.create attributes,
      wait: true
      beforeSend: ->
        $(self.el).find('textarea, .btn-success').addClass('disabled')
        $(self.el).find('.btn-success').text('Submitting...')
      success: (data) ->
        $(self.el).find('textarea, .btn-success').removeClass('disabled')
        $(self.el).find('textarea').text('').blur()
        $(self.el).find('.btn-success').text('Submit')
        createGrowl false, "Comment created", 'Success', 'green'
        globalSuccess(data)
        self.destroyForm()
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('textarea, .btn-success').removeClass('disabled')
        $(self.el).find('textarea').text('').blur()
        $(self.el).find('.btn-success').text('Submit')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('textarea, .btn-success').removeClass('disabled')
        $(self.el).find('textarea').text('').blur()
        $(self.el).find('.btn-success').text('Submit')

  catchEnter: (e) =>
    if e.keyCode == 13
      @createComment(e)

  destroyForm: =>
    if @modal
      $(@qtip).qtip('destroy')
    else
      $(@el).find('textarea').val('').blur()

  requireLogin: =>
    unless LL.App.current_user
      $(@el).find('textarea').blur()
      LL.LoginBox.showModal()
      return

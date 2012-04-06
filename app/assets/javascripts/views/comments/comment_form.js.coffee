class LL.Views.CommentForm extends Backbone.View
  template: JST['comments/form']
  id: 'comment-form'

  events:
      "click .submit": "createComment"
      "click .close,.cancel": "destroyForm"
      "keydown textarea": "catchEnter"

  initialize: ->
    @collection = new LL.Collections.Comments()
    @modal = false

  render: ->
    $(@el).html(@template(model: @model, modal: @modal))

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
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        createGrowl false, "Comment created", 'Success', 'green'
        globalSuccess(data)
        self.destroyForm()
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')

  catchEnter: (e) =>
    if e.keyCode == 13
      @createComment(e)

  destroyForm: =>
    if @modal
      $(@qtip).qtip('destroy')

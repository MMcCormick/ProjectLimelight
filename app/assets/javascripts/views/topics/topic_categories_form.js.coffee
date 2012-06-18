class LL.Views.TopicCategoryForm extends Backbone.View
  template: JST['topics/categories_form']
  tagName: 'div'
  className: 'section'
  id: 'topic-categories-form'

  events:
    'click .btn-success': 'updateTopic'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    $(@el).html(@template(topic: @model, categories: @collection.models))

    @

  updateTopic: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {category_id: $(@el).find('select').val()}

    self = @
    $.ajax @model.url()+'/categories',
      type: 'put'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Category')
        createGrowl false, "Category Added", 'Success', 'green'
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Category')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Category')
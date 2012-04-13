class LL.Views.TopicImageForm extends Backbone.View
  template: JST['topics/image_form']
  tagName: 'section'
  id: 'topic-image-form'

  events:
    'click .google-images .btn-success': 'updateTopicImage'
    'click .google-images .left': 'rotateImagesLeft'
    'click .google-images .right': 'rotateImagesRight'

  initialize: ->

  render: =>
    $(@el).html(@template(topic: @model))

    self = @
    url = "http://ajax.googleapis.com/ajax/services/search/images?rsz=large&start=0&v=1.0&q=#{@model.get('name')}"
    $.ajax url,
      dataType: 'jsonp'
      success: (data) ->
        console.log data
        if data.responseData.results.length > 0
          for image in data.responseData.results
            self.addGoogleImage(image)
          self.showImage($(self.el).find('.google-images img:first'))

    @

  addGoogleImage: (image) =>
    img = $('<img/>').attr('src', image.unescapedUrl).data({width: image.width, height: image.height}).hide()
    $(@el).find('.google-images').show().find('.images').append(img)

  showImage: (image) =>
    $(@el).find('.google-images img').hide()
    $(@el).find('.dimensions').text("#{image.data('width')}x#{image.data('height')}")
    image.show()

  rotateImagesLeft: (e) =>
    current = $(@el).find('.google-images img:visible')
    if current.prev().is('img')
      next = current.prev()
    else
      next = $(@el).find('.google-images img:last')
    @showImage(next)

  rotateImagesRight: (e) =>
    current = $(@el).find('.google-images img:visible')
    if current.next().is('img')
      next = current.next()
    else
      next = $(@el).find('.google-images img:first')
    @showImage(next)

  updateTopicImage: (e) =>
    return if $(e.currentTarget).hasClass('disabled')

    attributes = {id: @model.get('id'), url: $(@el).find('.google-images img:visible').attr('src')}

    self = @
    $.ajax '/api/topics/update_image',
      type: 'post'
      data: attributes
      beforeSend: ->
        $(e.currentTarget).addClass('disabled').text('Updating...')
      success: (data) ->
        $(self.el).find('.current-image').attr('src', data.url)
        $(e.currentTarget).removeClass('disabled').text('Use This Image')
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.currentTarget).removeClass('disabled').text('Use This Image')
        globalError(textStatus, $(self.el))
      complete: ->
        $(e.currentTarget).removeClass('disabled').text('Use This Image')

  updateTopic: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {id: @model.get('id')}
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"]')
      attributes[$(input).attr('name')] = $(input).val()
    for input in $(@el).find('input[type="checkbox"]')
      attributes[$(input).attr('name')] = $(input).val() if $(input).is(':checked')

    self = @
    $.ajax '/api/topics/connections',
      type: 'post'
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
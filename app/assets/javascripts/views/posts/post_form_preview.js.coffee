class LL.Views.PostFormPreview extends Backbone.View
  template: JST['posts/post_form_preview']
  className: 'preview-data'

  events:
    "click .switcher .left": "rotateImageLeft"
    "click .switcher .right": "rotateImageRight"
    "click .switcher .cancel-image": "cancelImage"

  initialize: ->
    @loaded = false
    @show_preview = true
    @collection.on('reset', @render)

  render: =>
    model = @collection.first()
    if model
      if model.get('id')
        embedly = new LL.Models.Embedly()
        embedly.set('limelight_post', new LL.Models.PostMedia(model))
        @setData(embedly)
      else
        @setData(model)
    else
      @remove()
    @

  setData: (model) =>
    if @show_preview

      $(@el).html(@template(model: model))

      $('#fetch-url-btn').removeClass('disabled').text('Fetch URL')
      if !@loaded
        $(@el).insertAfter(@target)
        @loaded = true

    if model.get('limelight_post')
      @post_form_model.set({
        'type': 'Post',
        'parent_id': model.get('limelight_post').get('id')
      })
    else
      @post_form_model.set({
        'type': model.get('type'),
        'source_url': model.get('url'),
        'title': model.get('title'),
        'provider_name': model.get('provider_name')
      })

    # initialize images
    if !model.get('limelight_post') && model.get('type') != 'Video' && model.get('images').length > 0
      @post_form_model.set('remote_image_url', model.get('images')[0].url)
      if model.get('images').length > 1 && @show_preview
        $(@el).find('.media img:gt(0)').hide() # hide all images but the first one
        $(@el).find('.switcher').show() # show the switcher

    # initialize video
    if model.get('type') == 'Video'
      @post_form_model.set('embed', model.get('video'))
      if model.get('images').length > 0
        @post_form_model.set('remote_image_url', model.get('images')[0].url)

    # change the help text
    if model.get('limelight_post')
      console.log $(@post_form).find('.step.one .desc')
      $(@post_form).find('.step.one .desc').text("Say something about this #{model.get('limelight_post').get('type')} (optional)")
    else
      $(@post_form).find('.step.one .desc').text("Say something about this #{model.get('type')} (optional)")

  setResponse: (model) ->
    embedly = new LL.Models.Embedly()
    embedly.set('limelight_post', model)
    @setData(embedly)

  cancelPreview: =>
    # clear the url field and the preview fields. reset to talk
    @post_form_model.clear()
    @post_form_model.set('type', 'Talk')
    $(@el).remove()
    @loaded = false

  rotateImageLeft: =>
    visible = $(@el).find('.media img:visible')
    prev = if visible.prev().length then visible.prev() else $(@el).find('.media img:last')
    visible.hide()
    prev.show()
    @post_form_model.set('remote_image_url', prev.attr('src'))

  rotateImageRight: =>
    visible = $(@el).find('.media img:visible')
    next = if visible.next().length then visible.next() else $(@el).find('.media img:first')
    visible.hide()
    next.show()
    @post_form_model.set('remote_image_url', next.attr('src'))

  cancelImage: (e) =>
    $(@el).find('.media').removeClass('with-image')
    $(@el).find('.switcher').hide()
    @post_form_model.set('remote_image_url', '')


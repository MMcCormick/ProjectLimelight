class LL.Views.PostFormPreview extends Backbone.View
  template: JST['posts/post_form_preview']
  tagName: 'div'
  className: 'preview'

  events:
    "click .cancel-preview": "destroyForm"
    "click .switcher .left": "rotateImageLeft"
    "click .switcher .right": "rotateImageRight"

  initialize: ->
    @loaded = false
    @collection.on('reset', @render, @)

  render: ->
    model = @collection.first()
    if model
      @setData(model)
    else
      @remove()
    @

  setData: (model) ->
    $(@el).html(@template(model: model))

    if !@loaded
      $(@el).insertAfter($('#post-form-fetch-url'))
      @loaded = true

    if model.get('limelight_post')
      @post_form.set({
        'type': 'Talk',
        'parent_id': model.get('limelight_post').id
      })
    else
      @post_form.set({
        'type': model.get('type'),
        'source_url': model.get('url'),
        'title': model.get('title'),
        'provider_name': model.get('provider_name')
      })

    # initialize images
    if !model.get('limelight_post') && model.get('type') != 'Video' && model.get('images').length > 0
      @post_form.set('remote_image_url', model.get('images')[0].url)
      if model.get('images').length > 1
        $(@el).find('.media img:gt(0)').hide() # hide all images but the first one
        $(@el).find('.switcher').show() # show the switcher

    # initialize video
    if model.get('type') == 'Video'
      @post_form.set('embed', model.get('video'))
      if model.get('images').length > 0
        @post_form.set('remote_image_url', model.get('images')[0].url)

  setResponse: (model) ->
    embedly = new LL.Models.Embedly()
    embedly.set({
      limelight_post: {
        id: model.get('id')
        title: model.get('title')
        type: model.get('type')
        embed: model.get('embed_html')
        image: model.get('image')
        created_at: model.get('created_at')
      }
    })
    @setData(embedly)

  destroyForm: ->
    # clear the url field and the preview fields. reset to talk
    @target.val('')
    @post_form.clear()
    @post_form.set('type', 'Talk')
    $(@el).remove()
    @loaded = false

  rotateImageLeft: =>
    visible = $(@el).find('.media img:visible')
    prev = if visible.prev().length then visible.prev() else $(@el).find('.media img:last')
    visible.hide()
    prev.show()
    @post_form.set('remote_image_url', prev.attr('src'))

  rotateImageRight: =>
    visible = $(@el).find('.media img:visible')
    next = if visible.next().length then visible.next() else $(@el).find('.media img:first')
    visible.hide()
    next.show()
    @post_form.set('remote_image_url', next.attr('src'))

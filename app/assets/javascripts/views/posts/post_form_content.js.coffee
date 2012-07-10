class LL.Views.PostFormContent extends Backbone.View
  template: JST['posts/form_content']

  events:
    "click .switcher .left": "rotateImageLeft"
    "click .switcher .right": "rotateImageRight"
    "click .cancel-image": "cancelImage"
    "click .type div": "handleTypeClick"
    "click .say-something": "showSaySomething"
    "click .mention-suggestions li": "useMentionSuggestion"
    "blur .topic-mention": "clearTopic"

  initialize: ->

  render: =>
    $(@el).html(@template(post: @model))

    @setData()
    
    self = @
    $(@el).find('input.topic-mention').each (i,val) ->
      $(val).soulmate
        url:            '/autocomplete/search',
        types:          ['topic'],
        minQueryLength: 2,
        maxResults:     10,
        allowNew:       true,
        selectFirst:    true,
        renderCallback: (term, data, type) ->
          html = term
          if data.data && data.data.type
            html += "<div class='topic-type'>#{data.data.type}</div>"
          html
        selectCallback: (term, data, type) ->
          name = if data.data then data.data.slug else 'new'
          self.addTopic($(val), data.term, data.id, name)
    @

  setData: =>
    $(@el).find('#post-form-source-url').val(@model.url)
    $(@el).find('#post-form-source-name').val(@model.provider_name)
    $(@el).find('#post-form-source-vid').val(@model.video)
    $(@el).find('#post-form-embed').val(@model.video)
    $(@el).find('#post-form-remote-image-url').val(@model.remote_image_url)
    $(@el).find('#post-form-image-cache').val(@model.image_cache)

    if @model.type
      @setType(@model.type)
    else
      @hidePostType()

    if @model.type == 'Video'
      @disableTypes(['Link', 'Picture'])

    unless @model.source_vid || @model.type == 'Video'
      @disableTypes(['Video'])

    if @model.images && @model.images.length > 0
      found = false

      for image in @model.images
        if image.width >= 300
          found = true

      unless found
        @disableTypes(['Picture'])

    else if @model.images
      @disableTypes(['Picture'])

    if @model.existing
      $(@el).find('#post-form-parent-id').val(@model.existing.id)

    # initialize images
    if !@model.existing && @model.images.length > 0
      if @model.images.length > 1
        $(@el).find('.media img:gt(0)').hide() # hide all images but the first one
        $(@el).find('.switcher').show() # show the switcher
      else
        $(@el).find('.switcher').show().find('.controls').hide() # show the switcher but not the controls

      $(@el).find('#post-form-remote-image-url').val($(@el).find('.media img:first').attr('src'))

  disableTypes: (types) =>
    for type in types
      $(@el).find(".type .#{type.toLowerCase()}").addClass('disabled').attr('title', 'This post type is disabled for this URL')

  setType: (type) =>
    $(@el).find('#post-form-type').val(type)
    $(@el).find('.type div').removeClass('on')
    $(@el).find(".type .#{type.toLowerCase()}").addClass('on')

  handleTypeClick: (e) =>
    return if $(e.currentTarget).hasClass('on') || $(e.currentTarget).hasClass('disabled')

    @setType($(e.currentTarget).data('type'))

  hidePostType: =>
    $(@el).find('.type').hide()

  showSaySomething: =>
    $(@el).find('.say-something').hide().next().show()

  useMentionSuggestion: (e) =>
    target = false
    $(@el).find('.mentions .topic-mention').each (i,val) ->
      if !target && $.trim($(val).val()) == ''
        target = $(val)

    unless target
      return

    @addTopic(target, $(e.currentTarget).text(), $(e.currentTarget).data('id'))

    $(e.currentTarget).remove()

    if $(@el).find('.mention-suggestions li').length == 0
      $(@el).find('.mention-suggestions').remove()

  rotateImageLeft: =>
    visible = $(@el).find('.media img:visible')
    prev = if visible.prev().length then visible.prev() else $(@el).find('.media img:last')
    visible.hide()
    prev.show()
    $(@el).find('#post-form-remote-image-url').val(prev.attr('src'))

  rotateImageRight: =>
    visible = $(@el).find('.media img:visible')
    next = if visible.next().length then visible.next() else $(@el).find('.media img:first')
    visible.hide()
    next.show()
    $(@el).find('#post-form-remote-image-url').val(next.attr('src'))

  cancelImage: (e) =>
    $(@el).find('.preview').removeClass('with-image')
    $(@el).find('.switcher').hide()
    $(@el).find('#post-form-remote-image-url').val('')

  clearTopic: (e) =>
    if $.trim($(e.currentTarget).val()) == ''
      topic = new LL.Models.Topic({id: $(e.currentTarget).next().val()})
      @removeTopicStat(topic)
      $(e.currentTarget).next().val('')

  addTopicStat: (topic) =>
    $(@el).find(".topic-default").hide()
    unless $(@el).find(".stats .t-#{topic.get('id')}").length > 0
      $(@el).find(".stats").append("<div class='topic-stat t-#{topic.get('id')}'>+#{topic.get('followers_count')} #{if topic.get('followers_count') != 1 then 'people' else 'person'} following #{topic.get('name')}</div>")

  removeTopicStat: (topic) =>
    $(@el).find(".stats .t-#{topic.get('id')}").remove()

  addTopic: (target, name, id) =>
    target.val(name).next().val(id)
    self = @
    if parseInt(id) != 0
      topic = new LL.Models.Topic({id: id})
      if topic.get('followers_count')
        @addTopicStat(topic)
      else
        topic.fetch(success: (model, response) -> self.addTopicStat(model))


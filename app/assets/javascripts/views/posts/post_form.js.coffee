class LL.Views.PostForm extends Backbone.View
  template: JST['posts/form']
  id: 'post-form'

  events:
      "focus textarea": "changeMinimal"
      "click .submit": "createPost"
      "click .cancel": "destroyForm"
      "click .close": "destroyForm"
      "click .icons .icon:not(.cancel-preview)": "activateType"
      "click .icons .cancel-preview": "removeEmbedly"
      "click #fetch-url-btn": "fetchEmbedly"
      "keyup #post-form-content": "monitorSpacebarUrl"
      "keypress #post-form-fetch-url": "monitorUrlEnter"
      "paste #post-form-content": "checkUrl"
      "paste #post-form-fetch-url": "fetchEmbedly"
      "blur .topic-mention": "clearTopic"

  initialize: ->
    @collection = new LL.Collections.Posts()

    @modal = false # display in a modal box?
    @with_header = true # show the header
    @cancel_buttons = false # display close/cancel buttons?
    @close_callback = null # optional close callback, must be a function
    @show_preview = true # show post previews? (links, pictures, videos)
    @minimal = false # only show the input field
    @initial_text = '' # initial text to show in the textarea
    @placeholder_text = 'Post something!' # initial placeholder text to show in the text area

    @model = new LL.Models.PostForm()
    @model.on('change', @updateFields)
    @model.on('change:type', @updateType)

    @embedly_collection = new LL.Collections.Embedly
    @preview = new LL.Views.PostFormPreview({collection: @embedly_collection, post_form_model: @model})
    @preview.post_form_model = @model

  render: =>
    $(@el).html(@template(modal: @modal, cancel_buttons: @cancel_buttons, with_header: @with_header, initial_text: @initial_text, placeholder_text: @placeholder_text))
    @preview.target = $(@el).find('.preview')

    # setTimeout to wait for the modal animation so that the autocomplete can position itself correctly
    self = @

    if @modal
      $(@el).addClass('modal fade')
      $(@el).modal()

    setTimeout ->
      $(self.el).find('input.topic-mention').each (i,val) ->
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
    , 1200

    $(@el).updatePolyfill()

    if @minimal
      $(@el).addClass('minimal')

    @

  createPost: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled') || e.keyCode == 13 || e.keyCode == 89

    e.preventDefault()

    attributes = {
      'topic_mention_ids': []
      'topic_mention_names': []
    }
    for input in $(@el).find('textarea, input[type="text"], input[type="hidden"], :not(.topic-mention, .topic-mention-id)')
      attributes[$(input).attr('name')] = $(input).val()

    for input in $(@el).find('.topic-mention')
      if $(input).next().val() && $(input).next().val() != '0'
        attributes['topic_mention_ids'].push $(input).next().val()
      else if $(input).val() && $(input).val() != ''
        attributes['topic_mention_names'].push $(input).val()

    self = @

    @collection.create attributes,
      wait: true
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        self.destroyForm()
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')

  destroyForm: ->
    if @modal
      $(@el).modal('hide')
    else if @minimal
      $(@el).addClass('minimal')
      @render()
    else if @close_callback
      @close_callback(@)


  updateFields: =>
    $(@el).find('#post-form-source-url').val(@model.get('source_url'))
    $(@el).find('#post-form-source-name').val(@model.get('provider_name'))
    $(@el).find('#post-form-source-vid').val(@model.get('source_vid'))
    $(@el).find('#post-form-embed').val(@model.get('embed'))
    $(@el).find('#post-form-parent-id').val(@model.get('parent_id'))
    $(@el).find('#post-form-remote-image-url').val(@model.get('remote_image_url'))
    $(@el).find('#post-form-image-cache').val(@model.get('image_cache'))

  addTopic: (target, name, id) =>
    target.val(name).next().val(id)
    self = @
    if id != "0"
      topic = new LL.Models.Topic({id: id})
      if topic.get('followers_count')
        @addTopicStat(topic)
      else
        topic.fetch(success: (model, response) -> self.addTopicStat(model))

  addTopicStat: (topic) =>
    $(@el).find(".topic-default").hide()
    unless $(@el).find(".stats .t-#{topic.get('id')}").length > 0
      $(@el).find(".stats").append("<div class='topic-stat t-#{topic.get('id')}'>+#{topic.get('followers_count')} user#{if topic.get('followers_count') != 1 then 's' else ''} following #{topic.get('name')}</div>")

  removeTopicStat: (topic) =>
    $(@el).find(".stats .t-#{topic.get('id')}").remove()
    if $(@el).find('.stats .topic-stat').length == 0
      $(@el).find(".topic-default").show()

  updateType: =>
    $(@el).find('#post-form-type').val(@model.get('type'))
    $(@el).find('.icons .icon').removeClass('on')

    if @model.get('type') == 'Talk' && !@model.get('parent_id')
      $(@el).find('.icons').removeClass('on').find('.cancel-preview').hide()
      $(@el).find('#post-form-fetch-url').val('').parent().hide()
    else
      $(@el).find('.icons .cancel-preview').show()
      switch @model.get('type')
        when 'Link'
          flag = true
          $(@el).find('.ll-icon-link').addClass('on')
        when 'Picture'
          flag = true
          $(@el).find('.ll-icon-picture').addClass('on')
        when 'Video'
          flag = true
          $(@el).find('.ll-icon-video').addClass('on')

  activateType: (e) =>
    # if we have not started a preview
    if $(@el).find('.preview:visible,.preview-data').length == 0
      $(@el).find('.preview').show()

    @model.set('type', $(e.target).data('type'))

  clearTopic: (e) =>
    if $.trim($(e.currentTarget).val()) == ''
      topic = new LL.Models.Topic({id: $(e.currentTarget).next().val()})
      @removeTopicStat(topic)
      $(e.currentTarget).next().val('')

  removeEmbedly: =>
    @preview.cancelPreview()

  checkUrl: (e) =>
    self = @

    # Need to use a timeout to wait until the paste content is in the input
    setTimeout ->
      urls = self.validateUrl($(e.target).val())

      if urls && urls[0]
        $(e.target).val($(e.target).val().replace(urls[0], ''))
        $(self.el).find('.ll-icon-link').click()
        $(self.el).find('#post-form-fetch-url').val(urls[0])
        self.fetchEmbedly()

    , 0


  monitorSpacebarUrl: (e) =>
    if e.keyCode == 32 # spacebar
      @checkUrl(e)

  fetchEmbedly: =>
    self = @

    # Need to use a timeout to wait until the paste content is in the input
    setTimeout ->
      $(self.el).find('.preview').show()

      return if $('#fetch-url-btn').hasClass('disabled')

      return unless $(self.el).find('#post-form-fetch-url').val().length > 5

      $('#fetch-url-btn').addClass('disabled').text('Fetching...')
      self.embedly_collection.fetch({data: {url: $(self.el).find('#post-form-fetch-url').val()}})
    , 0

  monitorUrlEnter: (e) =>
    if e.keyCode == 13 # enter keycode
      e.preventDefault()
      $(@el).find('#fetch-url-btn').click()
      return false

  focusTalk: =>
    $(@el).find('#post-form-content').focus()
    v = $(@el).find('#post-form-content').val()
    $(@el).find('#post-form-content').val('').val(v)

  validateUrl: (val) =>
    # http://stackoverflow.com/questions/6927719/url-regex-does-not-work-in-javascript
    val.match(/\b((?:[a-z][\w-]+:(?:\/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))/i)

  changeMinimal: (e) =>
    $(@el).removeClass('minimal')
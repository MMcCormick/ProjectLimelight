class LL.Views.PostForm extends Backbone.View
  template: JST['posts/form']
  id: 'post-form'

  events:
      "click .submit": "createPost"
      "click .cancel": "destroyForm"
      "click .find-url": "findUrl"
      'keypress .url': 'catchUrlEnter'
      "blur .url": 'blurUrl'
#      "click .close": "destroyForm"
      #"click #fetch-url-btn": "fetchEmbedly"
      #"keyup #post-form-content": "monitorSpacebarUrl"
      #"keypress #post-form-fetch-url": "monitorUrlEnter"
      #"paste #post-form-content": "checkUrl"
      #"paste #post-form-fetch-url": "fetchEmbedly"

  initialize: ->
    @collection = new LL.Collections.Posts()
    @close_callback = null # optional close callback, must be a function
    @model = null # represents the link
    @fetch_form = null
    @content_form = null
    @url = null

  render: =>
    $(@el).html(@template())

    self = @
    $(@el).addClass('modal fade').modal()

    if @model
      @showContent()
      for topic,i in @model.post.get('topic_mentions')
        @content_form.addTopic($(@el).find("#post-form-mention#{i+1}"), topic.get('name'), topic.get('id'), topic.get('slug'))
      $(@el).find('.fetch').remove()
    else
      @fetch_form = new LL.Views.PostFormFetch()
      $(@el).find('.fetch').html(@fetch_form.render().el)

    $(@el).updatePolyfill()

    @

  catchUrlEnter: (e) =>
    key = if e.charCode then e.charCode else if e.keyCode then e.keyCode else 0
    if key == 13
      $(@el).find('.find-url').click()

  blurUrl: (e) =>
    if ($(e.currentTarget).get(0).setSelectionRange)
      $(e.currentTarget).get(0).setSelectionRange(0, 0)
    else if ($(e.currentTarget).get(0).createTextRange)
      range = $(e.currentTarget).get(0).createTextRange()
      range.collapse(true)
      range.moveEnd('character', 0)
      range.moveStart('character', 0)
      range.select()

  findUrl: (e) =>
    @url = $(@el).find('.url').val()

    return if !@url || $.trim(@url).length == 0

    $(@el).find('.url').blur()

    $(@el).find('.find-url').addClass('disabled').text('Working...')

    self = @

    $.ajax '/embed',
      type: 'GET',
      data: {url: @url}
      success: (data) ->
        self.model = data
        if data.existing
          self.model.existing = new LL.Models.PostMedia($.parseJSON(data.existing))
        self.showContent()
        $(self.el).find('.find-url').removeClass('disabled').text('Find URL')
      error: (jqXHR, textStatus, errorThrown) ->

  showContent: () =>
    @content_form = new LL.Views.PostFormContent(model: @model)
    $(@el).find('.content').html(@content_form.render().el)

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
        LL.App.current_user.set('posts_count', LL.App.current_user.get('posts_count') + 1)
        self.destroyForm()
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')
        globalError(textStatus, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Submit')

  destroyForm: ->
    if @close_callback
      @close_callback(@)
    else
      $(@el).modal('hide')

  setModel: (model) =>
    @model = {
      share: model.get('share')
      existing: model
    }
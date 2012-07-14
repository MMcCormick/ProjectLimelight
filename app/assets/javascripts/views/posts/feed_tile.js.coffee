class LL.Views.FeedTile extends Backbone.View
  tagName: 'div'
  className: 'tile'
  template: JST['posts/tile']

  events:
    "click .root .img, .bg, h5": "postShow"
    "mouseenter": "cancelNewAnimation"
    "mouseenter .reasons": "showReasons"
    "mouseleave .reasons": "hideReasons"
    "click .mentions .delete": "deleteMention"
    "click .mentions .add": "showAddMention"
    "click .share-btn": "loadPostForm"
    "click .comment-btn": "toggleCommentForm"

  initialize: ->
    @responses = null
    @hovering = false
    @opened = false
    @addMentionForm = null
    @model.on('new_comment', @showComments)

  # This renders a root post
  # It adds the root to the top, followed by responses if there are any
  render: ->
    if @model.get('images') && @model.get('images').w >= 300
      @img_w = 300
    else if @model.get('images') && @model.get('images').w
      @img_w = @model.get('images').w

    if @img_w && @model.get('images').ratio
      @img_h = @img_w / @model.get('images').ratio

    $(@el).html(@template(post: @model, img_w: @img_w, img_h: @img_h))

    @comments_view = new LL.Views.CommentList(model: @model)
    form = new LL.Views.CommentForm(model: @model)
    form.minimal = true
    $(@el).find('.bottom').append($(form.render().el).hide()).append(@comments_view.render().el)
    if @model.get('comments') && @model.get('comments').length > 0
      $(@el).find('.bottom').show()

    if @model.get('share') && @model.get('share').get('topic_mentions').length > 0
      mentions = new LL.Views.PostMentions(model: @model.get('share'))
      $(@el).prepend(mentions.render().el)
    else if @model.get('topic_mentions').length > 0
      mentions = new LL.Views.PostMentions(model: @model)
      $(@el).prepend(mentions.render().el)

#    if @model.get('reasons').length > 0
#      reason_div = $('<div/>').addClass('reasons').html("<div class='earmark'>?</div><ul></ul>")
#      first = 'first'
#      for reason in @model.get('reasons')
#        reason_div.find('ul').append("<li class='#{first}'>#{reason}</li>")
#        first = ''
#      $(@el).find('.media').append(reason_div)

    @

  postShow: =>
    LL.Router.navigate("posts/#{@model.get('id')}", trigger: true)

  cancelNewAnimation: (e) =>
    # remove the red border that slowly fades out after a new post is pushed
    $(@el).removeClass('new').stop(true, true)

  showReasons: (e) =>
    $(@el).find('.reasons ul').fadeIn(200)

  hideReasons: (e) =>
    $(@el).find('.reasons ul').fadeOut(200)

  deleteMention: (e) =>
    $.ajax '/api/posts/mentions',
      type: 'delete'
      data: {id: @model.get('id'), topic_id: $(e.currentTarget).data('id')}
      beforeSend: ->
        $(e.currentTarget).addClass('disabled')
      success: (data) ->
        $(e.currentTarget).parent().remove()
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(e.currentTarget).removeClass('disabled')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(e.currentTarget).removeClass('disabled')

  showAddMention: (e) =>
    unless @addMentionForm
      @addMentionForm = new LL.Views.AddMentionForm(model: @model)
      $(e.currentTarget).after(@addMentionForm.render().el)

    $(@addMentionForm.el).fadeToggle(200)

  loadPostForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    view = new LL.Views.PostForm()
    view.setModel(@model)
    view.render()

  toggleCommentForm: =>
    self = @

    if $(@el).find('.comment-list li').length == 0
      target = $(@el).find('.bottom')
      target.find('.comment-form').show()
    else
      target = $(@el).find('.comment-form')

    if $(@el).find('.comment-form').is(':visible')
      target.slideUp 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).get(0))
    else
      target.slideDown 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).get(0))

  showComments: =>
    if $(@el).find('.bottom:visible').length == 0
      self = @
      $(self.el).find('.bottom').slideDown 100, ->
        $('#feed').isotope('shiftColumnOfItem', $(self.el).get(0))
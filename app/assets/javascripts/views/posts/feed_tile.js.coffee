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

  initialize: ->
    @responses = null
    @hovering = false
    @opened = false
    @addMentionForm = null

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
#    form = new LL.Views.CommentForm(model: @model.get('post'))
#    form.minimal = true
    $(@el).find('.bottom').html(@comments_view.render().el)
    if @model.get('comments').length > 0
      $(@el).find('.bottom').show()

#    mentions = new LL.Views.PostMentions(model: @model.get('post'))
#    $(@el).prepend(mentions.render().el)

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
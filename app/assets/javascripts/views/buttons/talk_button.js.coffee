class LL.Views.TalkButton extends Backbone.View
  className: 'talk'
  tagName: 'span'

  events:
    'click': 'loadPostForm'

  initialize: ->
    @button = false
    @user = null
    @topic1 = null
    @topic2 = null

  render: =>
    $(@el).html('+Talk')

    if @button == true
      $(@el).addClass('btn btn-success')

    @

  loadPostForm: =>
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    $('div.qtip:visible').qtip('hide');

    view = new LL.Views.PostForm()
    view.modal = true
    if @user
      view.initial_text += "@#{@user.get('username')} "

    if @topic1
      view.placeholder_text = "Talk about #{@topic1.get('name')}..."

    # add suport for topic2...

    view.render()

    if @topic1
      view.addTopic($(view.el).find('#post-form-mention1'), @topic1.get('name'), @topic1.get('id'))

    setTimeout ->
      view.focusTalk()
    , 500
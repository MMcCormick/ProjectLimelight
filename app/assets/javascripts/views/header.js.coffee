class LL.Views.Header extends Backbone.View
  el: $('body header .container')

  events:
    "click .talk": "loadPostForm"

  initialize: ->
    # only show if the user is not doing the tutorial
    if @model && @model.get('tutorial_step') == 0
      @render()

  render: =>
    header_user_nav = new LL.Views.UserHeaderNav(model: @model)
    $(@el).append(header_user_nav.render().el)

  loadPostForm: ->
    view = new LL.Views.PostForm()
    view.modal = true
    view.render()
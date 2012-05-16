class LL.Views.Header extends Backbone.View
  el: $('body header .container')

  events:
    "click .talk": "loadPostForm"

  initialize: ->
    # only show if the user is not doing the tutorial
    if (@model && @model.get('tutorial_step') == 0) || (!@model && window.location.pathname != '/')
      @render()

  render: =>
    header_search = new LL.Views.HeaderSearch()
    $(@el).append(header_search.render().el)

    header_user_nav = new LL.Views.UserHeaderNav(model: @model)
    $(@el).append(header_user_nav.render().el)

  loadPostForm: ->
    unless LL.App.current_user
      LL.LoginBox.showModal()
      return

    view = new LL.Views.PostForm()
    view.modal = true
    view.render()
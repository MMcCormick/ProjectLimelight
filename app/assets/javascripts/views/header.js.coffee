class LL.Views.Header extends Backbone.View
  el: $('body header .container')

  initialize: ->
    @model = LL.App.current_user
    @render()

  render: =>
    header_user_nav = new LL.Views.UserHeaderNav(model: @model)
    $(@el).append(header_user_nav.render().el)
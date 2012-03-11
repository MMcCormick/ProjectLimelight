class LL.Views.SplashPage extends Backbone.View
  template: JST['splash_page']
  id: 'splash-page'

  initialize: ->

  render: =>
    $(@el).html(@template())

    login = new LL.Views.UserLoginForm()
    $(@el).append(login.render().el)

    register = new LL.Views.UserRegisterForm(collection: LL.App.Users)
    $(@el).append(register.render().el)

    @
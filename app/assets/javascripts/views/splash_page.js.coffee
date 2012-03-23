class LL.Views.SplashPage extends Backbone.View
  el: $('body')

  events:
    'click .cheeky-buttons .login': 'showLogin'
    'click .cheeky-buttons .register': 'showInvite'
    'click .back': 'showCheekyButtons'

  initialize: ->
    login_form = new LL.Views.UserLoginForm()
    login_form.splash = @

    register_form = new LL.Views.UserRegisterForm(collection: LL.App.Users)
    register_form.splash = @

    invite_form = new LL.Views.UserUseInviteForm()
    invite_form.splash = @

    collection = new LL.Collections.SplashInfluenceIncreases()
    influences = new LL.Views.SplashInfluenceIncreases(collection: collection)
    collection.fetch()

  hideAll: =>
    $('.alert,.cheeky-buttons,.invite-form,.login-form,.register-form').hide()

  showLogin: =>
    @hideAll()
    $('.login-form').show()

  showRegister: =>
    @hideAll()
    $('.register-form').show()

  showInvite: =>
    @hideAll()
    $('.invite-form').show()

  showCheekyButtons: =>
    @hideAll()
    $('.cheeky-buttons').show()
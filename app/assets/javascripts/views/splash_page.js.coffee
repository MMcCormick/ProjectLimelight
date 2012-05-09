class LL.Views.SplashPage extends Backbone.View
  el: $('body')

  events:
    'click .beta-signup .account': 'showLogin'
    'click .beta-signup .invite-code': 'showInvite'
    'click .middle .back': 'showEnter'
    'click .bottom .about': 'showAbout'
    'click .bottom .team': 'showTeam'

  initialize: ->
    login_form = new LL.Views.UserLoginForm()
    login_form.splash = @

    register_form = new LL.Views.UserRegisterForm(collection: LL.App.Users)
    register_form.splash = @

    invite_form = new LL.Views.UserUseInviteForm()
    invite_form.splash = @

    invite_form = new LL.Views.UserBetaSignupForm()
    invite_form.splash = @

  hideAll: =>
    $('#splash-page .middle > div:visible').slideUp(300)

  showLogin: =>
    @hideAll()
    $('.beta-login').slideDown(300)

  showRegister: =>
    @hideAll()
    $('.beta-register').slideDown(300)

  showInvite: =>
    @hideAll()
    $('.invite-form').slideDown(300)

  showEnter: =>
    @hideAll()
    $('.beta-signup').slideDown(300)

  showAbout: =>
    @hideAll()
    $('.meat .beta-about').slideDown(300)

  showTeam: =>
    @hideAll()
    $('.meat .beta-team').slideDown(300)
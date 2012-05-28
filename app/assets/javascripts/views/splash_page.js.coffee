class LL.Views.SplashPage extends Backbone.View
  el: '#splash-page'

  events:
    'click .beta-signup .account': 'showLogin'
    'click .beta-signup .invite-code': 'showInvite'
    'click .middle .back': 'showEnter'
    'click .bottom .about': 'showAbout'
    'click .bottom .team': 'showTeam'

  initialize: ->
    login_form = new LL.Views.UserLoginForm(el: $(@el).find('.login-form form'))
    login_form.splash = @

    register_form = new LL.Views.UserRegisterForm(collection: new LL.Collections.Users, el: $(@el).find('.beta-register form'))
    register_form.splash = @

    invite_form = new LL.Views.UserUseInviteForm(el: $(@el).find('#new_invite_code'))
    invite_form.splash = @

    invite_form = new LL.Views.UserBetaSignupForm(el: $(@el).find('#beta-signup-form'))
    invite_form.splash = @

  showModal: =>
    $(@el).addClass('modal fade').modal()

  hideAll: =>
    $(@el).find('.middle > div:visible').slideUp(300)

  showLogin: =>
    @hideAll()
    self = @
    setTimeout ->
      $(self.el).find('.beta-login').slideDown(300)
    , 300

  showRegister: =>
    @hideAll()
    self = @
    setTimeout ->
      $(self.el).find('.beta-register').slideDown(300)
    , 300

  showInvite: =>
    @hideAll()
    self = @
    setTimeout ->
      $(self.el).find('.invite-form').slideDown(300)
    , 300

  showEnter: =>
    @hideAll()
    self = @
    setTimeout ->
      $(self.el).find('.beta-signup').slideDown(300)
    , 300

  showAbout: =>
    @hideAll()
    self = @
    setTimeout ->
      $(self.el).find('.meat .beta-about').slideDown(300)
    , 300

  showTeam: =>
    @hideAll()
    self = @
    setTimeout ->
      $(self.el).find('.meat .beta-team').slideDown(300)
    , 300
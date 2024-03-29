class LL.Views.UserHoverTab extends Backbone.View
  template: JST['users/hover_tab']

  initialize: ->

  render: =>
    self = @

    follow = new LL.Views.FollowButton(model: self.model)

    @target.qtip
      overwrite: false
      position:
        my: 'top left'
        at: 'bottom left'
        viewport: $(window)
      style:
        tip: false
        classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-limelight hover-tab'
      show:
        ready: true
        solo: true
      hide:
        fixed: true
        delay: 200
      content:
        text: (api) ->
          $(self.el).html(self.template(user: self.model))

          $(self.el).find('.bottom').append(follow.render().el)
          $(self.el)
      events:
        hide: (e,api) ->
          $(e.target).qtip('destroy')

    @

  setTarget: (el) =>
    @target = el
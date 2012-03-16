class LL.Views.UserHoverTab extends Backbone.View
  template: JST['users/hover_tab']

  initialize: ->

  render: =>
    self = @

    @target.qtip
      position:
        my: 'top left'
        at: 'bottom left'
        viewport: $(window)
      style:
        tip: false
        classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-limelight hover-tab'
      show: false
      hide:
        fixed: true
        delay: 300
        effect: (offset) ->
           $(@).slideUp(150) # "this" refers to the tooltip
      content:
        text: (api) ->
          $(self.el).html(self.template(user: self.model))

          follow = new LL.Views.FollowButton(model: self.model)
          $(self.el).find('.bottom').append(follow.render().el)
          $(self.el)

    @target.qtip('show')

    @

  setTarget: (el) =>
    @target = el
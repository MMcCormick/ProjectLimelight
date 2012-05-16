class LL.Views.UserHoverTab extends Backbone.View
  template: JST['users/hover_tab']

  initialize: ->
    @model.on("change", @render)

  render: =>
    self = @

    if @model.get('created_at')
      score = new LL.Views.Score(model: self.model)

      talk = new LL.Views.TalkButton()
      talk.user = self.model
      talk.button = true

      follow = new LL.Views.FollowButton(model: self.model)

      @target.qtip
        position:
          my: 'top left'
          at: 'bottom left'
          viewport: $(window)
          adjust:
            y: 15
            x: -5
        style:
          tip: false
          classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-limelight hover-tab'
        show: false
        hide:
          fixed: true
          delay: 300
        content:
          text: (api) ->
            $(self.el).html(self.template(user: self.model))

            $(self.el).find('.stat1').html(score.render().el)

            $(self.el).find('.bottom').append(talk.render().el).append(follow.render().el)

            $(self.el)

      @target.qtip('show')
    else
      LL.App.Users.findOrCreate(@model.get('id'), null, true)

    @

  setTarget: (el) =>
    @target = el
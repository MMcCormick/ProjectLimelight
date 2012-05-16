class LL.Views.TopicHoverTab extends Backbone.View
  template: JST['topics/hover_tab']

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->
    @model.on("change", @render)

  render: =>
    self = @

    if @model.get('created_at')
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
            $(self.el).html(self.template(topic: self.model))

            score = new LL.Views.Score(model: self.model)
            $(self.el).find('.stat1').html(score.render().el)

            talk = new LL.Views.TalkButton()
            talk.topic1 = self.model
            talk.button = true
            $(self.el).find('.bottom').append(talk.render().el)

            follow = new LL.Views.FollowButton(model: self.model)
            $(self.el).find('.bottom').append(follow.render().el)
            $(self.el)

      @target.qtip('show')
    else
      LL.App.Topics.findOrCreate(@model.get('id'), @model, true)

    @

  setTarget: (el) =>
    @target = el

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()

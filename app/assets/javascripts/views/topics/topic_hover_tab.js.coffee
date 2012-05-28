class LL.Views.TopicHoverTab extends Backbone.View
  template: JST['topics/hover_tab']

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->
    @model.on("change", @render)

  render: =>
    self = @

    score = new LL.Views.Score(model: self.model)

    talk = new LL.Views.TalkButton()
    talk.topic1 = self.model
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
          $(self.el).html(self.template(topic: self.model))

          $(self.el).find('.stat1').html(score.render().el)

          $(self.el).find('.bottom').append(talk.render().el).append(follow.render().el)
          $(self.el)

    @target.qtip('show')

    @

  setTarget: (el) =>
    @target = el

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()

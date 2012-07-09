class LL.Views.TopicHoverTab extends Backbone.View
  template: JST['topics/hover_tab']

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->

  render: =>
    self = @
#    score = new LL.Views.Score(model: @model)

    destroy = new LL.Views.TopicDestroyButton(model: @model)

    talk = new LL.Views.TalkButton()
    talk.topic1 = @model
    talk.button = true

    follow = new LL.Views.FollowButton(model: @model)

    @target.qtip
      overwrite: false
      position:
        my: 'top left'
        at: 'bottom left'
        viewport: $(window)
      style:
        classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-limelight hover-tab'
      show:
        ready: true
        solo: true
      hide:
        fixed: true
        delay: 200
      content:
        text: (api) ->
          $(self.el).html(self.template(topic: self.model))

#          $(self.el).find('.stat1').html(score.render().el)

          $(self.el).find('.bottom').append(destroy.render().el).append(talk.render().el).append(follow.render().el)
          $(self.el)
      events:
        hide: (e,api) ->
          $(e.target).qtip('destroy')

    @

  setTarget: (el) =>
    @target = el

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()

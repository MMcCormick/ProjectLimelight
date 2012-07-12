class LL.Views.TopicHoverTab extends Backbone.View
  template: JST['topics/hover_tab']

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->

  render: =>
    self = @

    destroy = new LL.Views.TopicDestroyButton(model: @model)

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

          if LL.App.current_user && LL.App.current_user.hasRole('admin')
            $(self.el).find('.bottom').append(destroy.render().el)

          $(self.el).find('.bottom').append(follow.render().el)
          $(self.el)
      events:
        hide: (e,api) ->
          $(e.target).qtip('destroy')

    @

  setTarget: (el) =>
    @target = el

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    view.render()
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()
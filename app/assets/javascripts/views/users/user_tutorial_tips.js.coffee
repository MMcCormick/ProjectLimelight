class LL.Views.UserTutorialTips extends Backbone.View

  initialize: ->

    self = @
    $('.tutorial-tip .next').live 'click', ->
      self.nextTip()

  render: =>
    switch @page
      when 'user_feed'
        @step = @model.get('tutorial1_step')

    return if @step == 0

    self = @
    setTimeout ->
      self.renderTip()
    , 2000

    @

  tutorial11: =>
    @target = $('.navbar .talk')
    @title = 'Speak Your Mind'
    @my = 'top center'
    @at = 'bottom center'
    @tip = true
    @button = 'Next'
    @content = '
      Click this button to talk about whatever videos, articles, pictures, or topics interest you.
      <br /><br />
      Add topics to your posts to reach more people and gain influence in those topics!
    '

  tutorial12: =>
    @target = $('#sidebar-influences')
    @title = 'Topic Influence'
    @my = 'left middle'
    @at = 'right middle'
    @tip = true
    @button = 'Next'
    @content = '
      A realtime view of the topic influence you\'re gaining as people like what you post about various topics.
      <br /><br />
      More topic influence means that more people will see what you post about that topic.
    '

  tutorial13: =>
    @target = $('#feed')
    @title = 'Your Feed'
    @my = 'top middle'
    @at = 'top middle'
    @tip = false
    @button = 'Finish'
    @content = '
      Limelight creates your feed based on the users and the topics that you\'re following.
      <br /><br />
      For each post, we show you what people you\'re following are saying about it, and what other users
      are saying about it.
      <br /><br />  +
      To see your feed sorted by popularity click the \'Popular\' button in the top right.
    '

  renderTip: =>

    switch @page
      when 'user_feed'
        switch @step
          when 1
            @tutorial11()
          when 2
            @tutorial12()
          when 3
            @tutorial13()
          else
            return
      else
        return

    @currentTip = @target.qtip
                    hide: false
                    position:
                      my: @my
                      at: @at
                    style:
                      tip: @tip
                      classes: 'ui-tooltip-shadow ui-tooltip-rounded ui-tooltip-limelight tutorial-tip'
                    content:
                      text: "
                        <div class='top'>#{@title}</div>
                        <div class='middle'>#{@content}</div>
                        <div class='bottom'>
                          <div class='btn next'>#{@button}</div>
                        </div>
                      "

    $('.qtip').qtip('hide')
    @currentTip.qtip('show')

  nextTip: =>
    switch @page
      when 'user_feed'
        if @step == 3
          @step = 0
        else
          @step += 1
        data = {'tutorial1_step': @step}

    $.ajax
      url: '/api/users'
      type: 'put'
      dataType: 'json'
      data: data

    if @step == 0
      $('.qtip').qtip('destroy')
    else
      @renderTip()
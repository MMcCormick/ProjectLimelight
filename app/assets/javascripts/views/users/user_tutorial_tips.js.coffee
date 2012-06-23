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

#  tutorial12: =>
#    @target = $('#sidebar-influences')
#    @title = 'Topic Influence'
#    @my = 'left middle'
#    @at = 'right middle'
#    @tip = true
#    @button = 'Next'
#    @content = '
#      A realtime view of the topic influence you\'re gaining as people like what you post about various topics.
#      <br /><br />
#      More topic influence means that more people will see what you post about that topic.
#    '

  tutorial11: =>
    @target = $('#page-header .feed')
    @title = 'Your Feed'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Next'
    @content = '
      This is your home on Limelight.
      <br /><br />
      Limelight creates your feed based on the users AND topics you\'re following.
    '

  tutorial12: =>
    @target = $('#page-header .posts')
    @title = 'Your Posts'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Next'
    @content = '
      You can find all of your previous posts here.
      <br /><br />
      Your posts are automatically organized around the topics you tag in them.
      <br /><br />
      You can click on any user to view their posts.
    '

  tutorial13: =>
    @target = $('#page-header .likes')
    @title = 'Your Likes'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Next'
    @content = '
      When you like a post on Limelight it is added to your Likes.
      <br /><br />
      Similar to your posts, Limelight organizes your Likes around topics.
      <br /><br />
      Every user has Likes, which can be accessed by clicking this "Likes" button on their profile.
    '

  tutorial14: =>
    @target = $('#page-header .topics')
    @title = 'Things You\'re Following'
    @my = 'top middle'
    @at = 'bottom right'
    @tip = true
    @button = 'Next'
    @content = '
      On Limelight you can follow users and topics.
      <br /><br />
      The users and topics you\'re following determine what is shown in your feed.
    '

  tutorial15: =>
    @target = $('.column .tile #post-form')
    @title = 'What do you want to say?'
    @my = 'left center'
    @at = 'right center'
    @tip = true
    @button = 'Finish'
    @content = '
      Your post can be just text (like a Tweet), or it can include a cool picture, video, or link.
      <br /><br />
      Tag a topic in your post to reach that topic\'s followers.
      <br /><br />
      Try clicking this box, adding the "Limelight" topic, and giving us some quick feedback! Or you can just press finish.
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
          when 4
            @tutorial14()
          when 5
            @tutorial15()
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
                      tip:
                        width: 12
                        height: 12
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
        if @step == 5
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
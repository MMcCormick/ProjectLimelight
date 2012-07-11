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
    @target = $('#page-header .home')
    @title = 'Your Feed'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Next'
    @content = '
      This is your home on Limelight.
      <br /><br />
      Your feed streams the latest Limelight posts based on the users AND topics you\'re following.
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
    @title = 'Topic Hub'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Next'
    @content = '
      On Limelight you can follow topics.
      <br /><br />
      Manage the topics you follow here.
      <br /><br />
      Topics are part of what determines the posts shown in your feed.
    '

  tutorial15: =>
    @target = $('#page-header .users')
    @title = 'User Hub'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Next'
    @content = '
      Manage the users you follow here.
      <br /><br />
      When you follow a user, their posts will show up in your feed.
    '

  tutorial16: =>
    @target = $('.navbar .talk')
    @title = 'Post a Link'
    @my = 'top middle'
    @at = 'bottom middle'
    @tip = true
    @button = 'Finish'
    @content = '
      On Limelight you post links to things on the web. You can post a link to anything (video, picture, article, blog post, etc).
      <br /><br />
      Tag 1-2 topics to organize your post. Your post will also be shown to the tagged topic\'s followers.
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
          when 6
            @tutorial16()
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
        if @step == 6
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
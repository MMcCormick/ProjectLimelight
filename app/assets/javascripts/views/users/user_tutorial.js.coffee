class LL.Views.UserTutorial extends Backbone.View
  template: JST['users/tutorial']
  id: 'tutorial'

  events:
    'click .next': 'displayNext'
    'click .follow': 'updateFollowCount'

  initialize: ->
    @followCount = 0

  render: =>
    $(@el).html(@template(user: @model, step: @step))

    view = new LL.Views["UserTutorial#{@step}"](model: LL.App.current_user)
    view.parent = @
    @activeView = view

    @displayActive(true)

    if @step < 4
      next = new LL.Views["UserTutorial#{@step+1}"](model: LL.App.current_user)
      next.parent = @
      @nextView = next

    @

  updateFollowCount: =>
    return unless @step == 2

    self = @
    setTimeout ->
      self.activeView.followCount = $('.follow:contains("Unfollow")').length
      if self.activeView.followCount >= 3
        $(self.el).find('.next').removeClass('disabled').text('Next')
      else
        $(self.el).find('.next').addClass('disabled').text('Follow 3 Topics First')
    , 1000

  changeValues: =>
    $(@el).find('h2').text(@activeView.title)

    $(@el).find('.modal-body').html(@activeView.render().el)

    $(@el).find('.step-count span').text(@step)

    if @step == 2 && @followCount < 3 && $('.follow').length > 0
      $(@el).find('.next').addClass('disabled').text('Follow 3 Topics First')

    if @step == 4
      setTimeout ->
        $('.next').text('Finish!')
      , 400

  displayActive: (first=false) =>
    self = @

    $('body').scrollTop(0)

    if first == true

      @changeValues()

    else
      tile = $(@el).find('.content-tile')
      adjust = tile.offset().left + tile.width()
      tile.animate {left: "-#{adjust}px"}, 500, 'easeOutExpo', ->
        self.changeValues()
        tile.css(left: $('body').width()).animate {left: "0px"}, 500, 'easeOutExpo'



  displayNext: =>

    if $(@el).find('.next').hasClass('disabled') && @followCount < 3
      switch @step
        when 2
          createGrowl(false, 'Please follow at least 3 topics before moving on', 'Woops', 'red')
      return

    if @step < 4

      @step += 1

      $.ajax
        url: '/api/users'
        type: 'put'
        dataType: 'json'
        data: {'tutorial_step': @step}
        beforeSend: ->
          $('.next').addClass('disabled')
        complete: ->
          $('.next').removeClass('disabled')

      @activeView = @nextView

      @displayActive()

      if @step < 4
        next = new LL.Views["UserTutorial#{@step+1}"](model: LL.App.current_user)
        next.parent = @
        @nextView = next
      else
        $('.next').text('Finish!')

    else

      $.ajax
        url: '/api/users'
        type: 'put'
        dataType: 'json'
        data: {'tutorial_step': 0}
        complete: ->
          window.location = '/'


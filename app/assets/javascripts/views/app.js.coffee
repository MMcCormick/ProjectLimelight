class LL.Views.App extends Backbone.View
  el: $('body')

  initialize: ->
    self = @

    @model = new LL.Models.App()

    # The currently active feed
    @Feed = null

    # set the global collections
    @Users = new LL.Collections.Users
    @UserFeed = new LL.Collections.UserFeed
    @LikeFeed = new LL.Collections.LikeFeed
    @UserFollowers = new LL.Collections.UserFollowers

    @Posts = new LL.Collections.Posts

    @Topics = new LL.Collections.Topics
    @TopicFeed = new LL.Collections.TopicFeed
    @TopicSuggestions = new LL.Collections.TopicSuggestions

    @Modal = new LL.Views.Modal

    # set the current user
    @current_user = if $('#me').length > 0 then @Users.findOrCreate($('#me').data('user').id, new LL.Models.User($('#me').data('user'))) else null

    # needs to be in an initializer to bind it to the window instead of this collection element
    $(window).resize ->
      self.calculateSiteWidth(false)

  calculateSiteWidth: =>
    width = $(window).width()

#    if width >= 1475
#      className = 'five'
    if width >= 1235
      className = 'four'
    else if width >= 995
      className = 'three'
    else
      className = 'two'

    unless $('body').hasClass(className)
      $('body').removeClass('two three four five').addClass(className)
      @trigger('rearrange_columns')
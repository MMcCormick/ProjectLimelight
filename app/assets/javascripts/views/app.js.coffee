class LL.Views.App extends Backbone.View
  el: $('body')

  initialize: ->
    self = @

    @model = new LL.Models.App()

    # set the global collections
    @Users = new LL.Collections.Users
    @UserFeed = new LL.Collections.UserFeed

    @Posts = new LL.Collections.Posts
    @PostFriendResponses = new LL.Collections.PostFriendResponses
    @PostPublicResponses = new LL.Collections.PostPublicResponses

    @Topics = new LL.Collections.Topics
    @TopicFeed = new LL.Collections.TopicFeed
    @TopicSuggestions = new LL.Collections.TopicSuggestions

    # set the current user
    @current_user = if $('#me').length > 0 then @Users.findOrCreate($('#me').data('user').id, new LL.Models.User($('#me').data('user'))) else null

    # needs to be in an initializer to bind it to the window instead of this collection element
    @calculateSiteWidth(true)
    $(window).resize ->
      self.calculateSiteWidth(false)

  calculateSiteWidth: (first) =>
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
      @trigger('rearrange_columns') unless first == true
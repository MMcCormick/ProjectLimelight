class LL.Views.App extends Backbone.View
  el: $('body')

  initialize: ->
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
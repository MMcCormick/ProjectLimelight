class LL.Views.App extends Backbone.View
  el: $('body')

  events:
    "click .talk": "loadPostForm"

  initialize: ->
    @model = new LL.Models.App()

    # set the global collections
    @UserFeed = new LL.Collections.UserFeed
    @TopicFeed = new LL.Collections.TopicFeed
    @Users = new LL.Collections.Users
    @Topics = new LL.Collections.Topics
    @Posts = new LL.Collections.Posts
    @TopicSuggestions = new LL.Collections.TopicSuggestions
    @PostFriendResponses = new LL.Collections.PostFriendResponses
    @PostPublicResponses = new LL.Collections.PostPublicResponses()

    # set the current user
    @current_user = if $('#me').length > 0 then @Users.findOrCreate($('#me').data('user').id, new LL.Models.User($('#me').data('user'))) else null

  loadPostForm: ->
    view = new LL.Views.PostForm()
    view.render().el
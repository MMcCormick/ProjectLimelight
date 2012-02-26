class LL.Views.App extends Backbone.View
  el: $('body')

  events:
    "click .post-form": "loadPostForm"

  initialize: ->
    @model = new LL.Models.App()

    # set the global collections
    @UserFeed = new LL.Collections.UserFeed
    @Users = new LL.Collections.Users
    @Topics = new LL.Collections.Topics
    @Posts = new LL.Collections.Posts
    @TopicSuggestions = new LL.Collections.TopicSuggestions

    # set the current user
    @current_user = @Users.findOrCreate($('#me').data('user').id, new LL.Models.User($('#me').data('user')))

  loadPostForm: ->
    view = new LL.Views.PostForm()
    $(@el).append(view.render().el)
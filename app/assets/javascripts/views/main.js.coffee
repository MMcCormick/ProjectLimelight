class LL.Views.Main extends Backbone.View
  el: $('body')

  events:
    "click .post-form": "loadPostForm"

  loadPostForm: ->
    view = new LL.Views.PostForm()
    $(@el).append(view.render().el)
class LL.Views.RootMedia extends Backbone.View
  template: JST['posts/root_media']
  tagName: 'div'
  className: 'root'

  events:
    "click .talk-form": "loadPostForm"

  initialize: ->

  render: ->
    $(@el).addClass(@model.get('type').toLowerCase()).html(@template(post: @model))

    prettyTime = new LL.Views.PrettyTime()
    prettyTime.format = 'extended'
    prettyTime.time = @model.get('created_at')
    $(@el).find('.when').prepend(prettyTime.render().el)

    like = new LL.Views.LikeButton(model: @model)
    $(@el).find('.actions').prepend(like.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).find('.actions').prepend(score.render().el)

    @

  loadPostForm: =>
    view = new LL.Views.PostForm()
    view.modal = true
    view.placeholder_text = "Talk about this #{@model.get('type')}..."
    view.render().el
    i = 1
    for topic in @model.get('topic_mentions')
      view.addTopic($(view.el).find("#post-form-mention#{i}"), topic.name, topic.id)
      break if i == 2
      i++

    view.preview.setResponse(@model)
    $(view.el).find('.icons').remove()
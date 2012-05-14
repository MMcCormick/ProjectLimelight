class LL.Views.UserListItem extends Backbone.View
  template: JST['users/list_item']
  tagName: 'li'

  initialize: ->

  render: =>
    $(@el).addClass('odd') if @odd
    $(@el).append(@template(user: @model))

    if !LL.App.current_user || LL.App.current_user.get('id') != @model.get('id')
      follow = new LL.Views.FollowButton(model: @model)
      $(@el).find('.follow-c').html(follow.render().el)

    score = new LL.Views.Score(model: @model)
    $(@el).append(score.render().el)

    @
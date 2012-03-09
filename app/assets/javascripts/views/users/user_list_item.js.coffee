class LL.Views.UserListItem extends Backbone.View
  template: JST['users/list_item']
  tagName: 'li'

  initialize: ->

  render: =>
    $(@el).append(@template(user: @model))

    @
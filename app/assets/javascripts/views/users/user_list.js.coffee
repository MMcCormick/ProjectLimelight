class LL.Views.UserList extends Backbone.View
  template: JST['users/list']
  tagName: 'div'
  className: 'content-tile user-list'

  initialize: ->
    @collection.on('reset', @render)
    @collection.on('add', @appendUser)

    # Always start on page 1
    #@.page = 1

  render: =>
    $(@el).html(@template())
    $('#feed').html(@el)

    for user,i in @collection.models
      @appendUser(user, i%2)

    @

  appendUser: (user, odd) =>
    view = new LL.Views.UserListItem(model: user)
    view.odd = odd
    $(@el).find('ul').append(view.render().el)

    @
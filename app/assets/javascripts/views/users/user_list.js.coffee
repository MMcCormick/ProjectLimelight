class LL.Views.UserList extends Backbone.View
  template: JST['users/list']
  tagName: 'div'
  className: 'content-tile user-list'

  initialize: ->
    @pageTitle = ''
    @half = false
    @collection.on('reset', @render)
    @collection.on('add', @appendUser)

    # Always start on page 1
    #@.page = 1

  render: =>
    $(@el).html(@template())

    if @half
      $(@el).addClass('half')

    $('#feed').append(@el)

    if @pageTitle != ''
      $(@el).find('.section').prepend("<div class='top'><h4>#{@pageTitle}</h4></div>")

    if @collection.models.length == 0
      $(@el).find('.section').append("<div class='none'>Hmm, there's nothing to show here</div>")
    else
      for user,i in @collection.models
        @appendUser(user, i%2)

    @

  appendUser: (user, odd) =>
    view = new LL.Views.UserListItem(model: user)
    view.odd = odd
    $(@el).find('ul').append(view.render().el)

    @
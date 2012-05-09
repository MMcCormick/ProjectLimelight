class LL.Views.UserInfluence extends Backbone.View
  template: JST['users/influence']
  el: '#feed'
  id: 'user-influence-page'

  initialize: =>

  render: =>
    $(@el).html(@template())

    @increases = new LL.Collections.InfluenceIncreases()
    @increases_view = new LL.Views.InfluenceIncreasesFull(collection: @increases)
    $('.increases .meat').append(@increases_view.render().el)

    @increases.fetch({data: {id: @user.get('slug'), limit: 10, with_post: true}})

    @
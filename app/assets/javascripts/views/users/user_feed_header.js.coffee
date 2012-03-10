class LL.Views.UserFeedHeader extends Backbone.View
  template: JST['users/feed_header']
  id: 'user-feed-header'
  className: 'feed-header'

  initialize: ->
    $('#user-feed-header').remove()

  render: =>
    $(@el).html(@template(user: @model))
    $('#feed').prepend($(@el))

    # Influence strip
    influences_collection = new LL.Collections.InfluenceIncreases()
    influences = new LL.Views.InfluenceIncreases(collection: influences_collection, model: @model)
    influences_collection.fetch({data: {id: @model.get('slug')}})
    $('#feed').append(influences.el)

    @
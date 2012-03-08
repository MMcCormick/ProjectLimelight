class LL.Views.UserFeedHeader extends Backbone.View
  template: JST['users/feed_header']
  id: 'user-feed-header'
  className: 'feed-header'

  initialize: ->
    @loaded = null

  render: =>
    return if @loaded
    @loaded = true

    $(@el).html(@template(user: @model))
    $('#feed').prepend($(@el))

    # Influence strip
    influences_collection = new LL.Collections.InfluenceIncreases()
    influences = new LL.Views.InfluenceIncreases(collection: influences_collection)
    influences_collection.fetch({data: {id: @model.get('slug')}})
    $('#feed').append(influences.el)

    @
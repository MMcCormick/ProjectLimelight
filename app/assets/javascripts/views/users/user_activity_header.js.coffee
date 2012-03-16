class LL.Views.UserActivityHeader extends Backbone.View
  template: JST['users/activity_header']
  id: 'user-activity-header'
  className: 'feed-header'

  initialize: ->
    $('#user-activity-header').remove()

  render: =>
    $(@el).html(@template(user: @model))
    $('#feed').prepend($(@el))

    # Influence strip
    influences_collection = new LL.Collections.InfluenceIncreases()
    influences = new LL.Views.InfluenceIncreases(collection: influences_collection, model: @model)
    influences_collection.fetch({data: {id: @model.get('slug')}})
    $('#feed').append(influences.el)

    @
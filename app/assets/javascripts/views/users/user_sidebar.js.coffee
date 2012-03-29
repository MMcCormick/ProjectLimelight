class LL.Views.UserSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'user-sidebar'

  initialize: ->

  render: =>
    # Profile image
    $(@el).append("<img class='profile-image' src='#{@model.get('images').cropped.large}' />")

    # User talk form
    talk = new LL.Views.UserSidebarTalk(model: @model)
    $(@el).append(talk.render().el)

    # Influence strip
    influences_collection = new LL.Collections.InfluenceIncreases()
    influences = new LL.Views.InfluenceIncreases(collection: influences_collection, model: @model)
    $(@el).append(influences.el)
    influences_collection.fetch({data: {id: @model.get('slug')}})

    # Topic suggestions
#    if LL.App.current_user == @model
#      topic_suggestions = new LL.Views.UserSidebarTopicSuggestions(model: @model)
#      $(@el).append(topic_suggestions.el)
#      LL.App.TopicSuggestions.fetch({data: {id: @model.id}})

    # Static Links
    footer = new LL.Views.SidebarFooter()
    $(@el).append(footer.render().el)

    @
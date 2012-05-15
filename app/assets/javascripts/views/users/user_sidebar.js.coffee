class LL.Views.UserSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'user-sidebar'

  initialize: ->

  render: =>
    # Profile image
    $(@el).append("<img class='profile-image' src='#{@model.get('images').fit.large}' />")

    # User talk form
    talk = new LL.Views.UserSidebarTalk(model: @model)
    $(@el).append(talk.render().el)

    # Invite Code
    if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id')
      invite = new LL.Views.UserSidebarInvite(model: LL.App.current_user)
      $(@el).append(invite.render().el)

    # Influence strip
    influences_collection = new LL.Collections.InfluenceIncreases()
    influences = new LL.Views.InfluenceIncreases(collection: influences_collection, model: @model)
    $(@el).append(influences.el)
    influences_collection.fetch({data: {id: @model.get('slug'), limit: 3, with_post: false}})

    # Social connect
    if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id') && (!@model.get('facebook_id') || !@model.get('twitter_id'))
      connect = new LL.Views.UserSidebarSocialConnect(model: LL.App.current_user)
      $(@el).append(connect.render().el)


    # Topic suggestions
#    if LL.App.current_user == @model
#      topic_suggestions = new LL.Views.UserSidebarTopicSuggestions(model: @model)
#      $(@el).append(topic_suggestions.el)
#      LL.App.TopicSuggestions.fetch({data: {id: @model.id}})

    # Static Links
    footer = new LL.Views.SidebarFooter()
    $(@el).append(footer.render().el)

    @
class LL.Views.UserSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'user-sidebar'

  initialize: ->

  render: =>
    # Profile image
    $(@el).append("<img class='profile-image' src='#{@model.get('images').fit.large}' />")

    if !LL.App.current_user || LL.App.current_user.get('id') != @model.get('id')
      follow = new LL.Views.FollowButton(model: @model)
      $(@el).append(follow.render().el)

    # Invite Code
    if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id') && LL.App.current_user.get('invite_code')
      invite = new LL.Views.UserSidebarInvite(model: LL.App.current_user)
      $(@el).append(invite.render().el).append("<div class='bb'></div>")

    # Other Following
    $(@el).append("<h5><a href='#{if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id') then '/users' else @model.get('url')+'/users'}'>#{@model.get('followers_count')} Followers</a></h5>")
    $(@el).append("<div class='bb'></div>")
    $(@el).append("<h5><a href='#{if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id') then '/users' else @model.get('url')+'/users'}'>Following #{@model.get('following_users_count')} Users</a></h5>")

    # Following Topics
    collection = new LL.Collections.UserFollowingTopics()
    collection.id = @model.get('id')
    collection.limit = 5
    following_topics = new LL.Views.SidebarTopicList(collection: collection)
    following_topics.title = "<a href='#{if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id') then '/topics' else @model.get('url')+'/topics'}'>Following #{@model.get('following_topics_count')} Topics</a>"
    $(@el).append(following_topics.render().el)
    if @model.get('following_topics_count') > 0
      collection.fetchItems()

    # Social connect
#    if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id') && (!@model.get('facebook_id') || !@model.get('twitter_id'))
#      connect = new LL.Views.UserSidebarSocialConnect(model: LL.App.current_user)
#      $(@el).append(connect.render().el)

    # Topic suggestions
#    if LL.App.current_user == @model
#      topic_suggestions = new LL.Views.UserSidebarTopicSuggestions(model: @model)
#      $(@el).append(topic_suggestions.el)
#      LL.App.TopicSuggestions.fetch({data: {id: @model.id}})

    # Static Links
    footer = new LL.Views.SidebarFooter()
    $(@el).append(footer.render().el)

    @
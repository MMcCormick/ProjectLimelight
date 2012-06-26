class LL.Views.TopicSidebar extends Backbone.View
  el: $('.sidebar')
  id: 'topic-sidebar'

  events:
    "click .edit-btn": "loadEditModal"

  initialize: ->

  render: =>

    # Profile image
    $(@el).append("<img class='profile-image' src='#{@model.get('images').fit.large}' />")

    # Talk form
#    talk = new LL.Views.TopicSidebarTalk(model: @model)
#    $(@el).append(talk.render().el)

    follow = new LL.Views.FollowButton(model: @model)
    $(@el).find('.actions').prepend(follow.render().el)

    if LL.App.current_user && LL.App.current_user.hasRole('admin')
      admin = new LL.Views.TopicSidebarAdmin(model: @model)
      $(@el).append(admin.render().el)

    if @model.get('summary')
      info = new LL.Views.TopicSidebarInfo(model: @model)
      $(@el).append(info.render().el)

    if @model.get('aliases').length > 0
      aliases = new LL.Views.TopicSidebarAliases(model: @model)
      $(@el).append(aliases.render().el)

    if @model.get('websites').length > 0
      websites = new LL.Views.TopicSidebarWebsites(model: @model)
      $(@el).append(websites.render().el)

    # Static Links
    footer = new LL.Views.SidebarFooter()
    $(@el).append(footer.render().el)

    @

  loadEditModal: (e) =>
    view = new LL.Views.TopicEdit(model: @model)
    LL.App.Modal.add("topic_edit", view).setActive("topic_edit").show()
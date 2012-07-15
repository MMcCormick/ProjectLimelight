class LL.Views.UserPageHeader extends Backbone.View

  initialize: =>
    @model.on('change:share_count', @updateShareCount)

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('name')
    header.subtitle = "@#{@model.get('username')}"
    header.links = [
      {
        class: 'posts'
        content: "<span>#{@model.get('share_count')}</span> Shares"
        url: (if LL.App.current_user == @model then '/activity' else "#{@model.get('url')}")
        on: (if @page == 'posts' then true else false)
      }
      {
        class: 'topics'
        content: "Topics"
        url: (if LL.App.current_user == @model then '/topics' else "#{@model.get('url')}/topics")
        on: (if @page == 'topics' then true else false)
      }
      {
        class: 'users'
        content: "Users"
        url: (if LL.App.current_user == @model then '/users' else "#{@model.get('url')}/users")
        on: (if @page == 'users' then true else false)
      }
    ]

    if LL.App.current_user && LL.App.current_user.get('id') == @model.get('id')
      header.links.unshift(
        {
          class: 'home'
          content: 'Home'
          url: '/'
          on: (if @page == 'home' then true else false)
        }
      )

#    if @page == 'feed'
#      header.showSorting = true

    header.render()

    @

  updateShareCount: =>
    $('#page-header').find('.posts a').animate {color: 'red'}, 2000, ->
      $(@).animate {color: 'black'}, 2000

    $('#page-header').find('.posts span').text(@model.get('share_count'))
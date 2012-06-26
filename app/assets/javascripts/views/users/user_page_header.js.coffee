class LL.Views.UserPageHeader extends Backbone.View

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('name')
    header.subtitle = "@#{@model.get('username')}"
    header.links = [
      {
        class: 'posts'
        content: "#{@model.get('posts_count')} Posts"
        url: (if LL.App.current_user == @model then '/activity' else "#{@model.get('url')}")
        on: (if @page == 'posts' then true else false)
      }
      {
        class: 'likes'
        content: "#{@model.get('likes_count')} Likes"
        url: (if LL.App.current_user == @model then '/likes' else "#{@model.get('url')}/likes")
        on: (if @page == 'likes' then true else false)
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
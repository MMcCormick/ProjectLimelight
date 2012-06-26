class LL.Views.UserPageHeader extends Backbone.View

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('name')
    header.subtitle = "@#{@model.get('username')}"
    header.links = [
      {
        class: 'posts'
        content: "<span>#{@model.get('posts_count')}</span> Posts"
        url: (if LL.App.current_user == @model then '/activity' else "/users/#{@model.get('slug')}")
        on: (if @page == 'posts' then true else false)
      }
#      {
#        content: "<span>#{@model.get('likes_count')}</span> Likes"
#        url: (if LL.App.current_user == @model then '/likes' else "/users/#{@model.get('slug')}/likes")
#        on: (if @page == 'likes' then true else false)
#      }
      {
        class: 'topics'
        content: "Topics"
        url: (if LL.App.current_user == @model then '/topics' else "/users/#{@model.get('slug')}/topics")
        on: (if @page == 'topics' then true else false)
      }
      {
        class: 'users'
        content: "Users"
        url: (if LL.App.current_user == @model then '/users' else "/users/#{@model.get('slug')}/users")
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
class LL.Views.UserPageHeader extends Backbone.View

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('username')
    header.showScore = true
    header.showFollow = true
    header.links = [
      {
        content: (if LL.App.current_user == @model then 'My Feed' else "Feed")
        url: (if LL.App.current_user == @model then '/' else "/users/#{@model.get('slug')}/feed")
        on: (if @page == 'feed' then true else false)
      }
      {
        content: "<span>#{@model.get('likes_count')}</span> Posts"
        url: (if LL.App.current_user == @model then '/activity' else "/users/#{@model.get('slug')}")
        on: (if @page == 'activity' then true else false)
      }
      {
        content: "<span>#{@model.get('likes_count')}</span> Likes"
        url: (if LL.App.current_user == @model then '/likes' else "/users/#{@model.get('slug')}/likes")
        on: (if @page == 'likes' then true else false)
      }
#      {
#        content: "Influence"
#        url: (if LL.App.current_user == @model then '/influence' else "/users/#{@model.get('slug')}/influence")
#        on: (if @page == 'influence' then true else false)
#      }
      {
        content: "<span>#{@model.get('following_topics_count')}</span> Topics"
        url: "/users/#{@model.get('slug')}/following/topics"
        on: (if @page == 'following_topics' then true else false)
      }
      {
        content: "<span>#{@model.get('following_users_count')}</span> Users"
        url: "/users/#{@model.get('slug')}/following/users"
        on: (if @page == 'following_users' then true else false)
      }
      {
        content: "<span>#{@model.get('followers_count')}</span> Followers"
        url: "/users/#{@model.get('slug')}/followers"
        on: (if @page == 'followers' then true else false)
      }
    ]

#    if @page == 'feed'
#      header.showSorting = true

    header.render()
    @
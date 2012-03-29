class LL.Views.UserPageHeader extends Backbone.View

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('username')
    header.showScore = true
    header.showFollow = true
    header.links = [
      {
        content: "Feed"
        url: (if LL.App.current_user == @model then '/' else "/users/#{@model.get('slug')}")
        on: (if @page == 'feed' then true else false)
      }
      {
        content: "Likes"
        url: (if LL.App.current_user == @model then '/likes' else "/users/#{@model.get('slug')}/likes")
        on: (if @page == 'likes' then true else false)
      }
      {
        content: "Activity"
        url: (if LL.App.current_user == @model then '/activity' else "/users/#{@model.get('slug')}/activity")
        on: (if @page == 'activity' then true else false)
      }
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
    header.render()
    @
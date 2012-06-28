class LL.Views.TopicPageHeader extends Backbone.View

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('name')
    if @model.get('primary_type')
      header.subtitle = @model.get('primary_type')

    header.links = [
      {
        class: 'feed'
        content: "Feed"
        url: (if LL.App.current_user == @model then '/' else "#{@model.get('url')}")
        on: (if @page == 'feed' then true else false)
      }
      {
        class: 'users'
        content: "Users"
        url: "#{@model.get('url')}/users"
        on: (if @page == 'followers' then true else false)
      }
    ]

    if @page == 'feed'
      header.showSorting = true

    header.render()

    @
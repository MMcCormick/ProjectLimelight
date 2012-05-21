class LL.Views.TopicPageHeader extends Backbone.View

  render: =>
    header = new LL.Views.PageHeader(model: @model)
    header.title = @model.get('name')
    header.showScore = true
    header.showFollow = true
    header.links = [
      {
        content: "Feed"
        url: (if LL.App.current_user == @model then '/' else "/#{@model.get('slug')}")
        on: (if @page == 'feed' then true else false)
      }
      {
        content: "<span>#{@model.get('followers_count')}</span> Followers"
        url: "/#{@model.get('slug')}/followers"
        on: (if @page == 'followers' then true else false)
      }
    ]

    if @page == 'feed'
      header.showSorting = true

    header.render()

    @
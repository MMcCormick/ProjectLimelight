class LL.Collections.UserFollowingTopics extends Backbone.Collection
  url: '/api/users/following_topics'
  model: LL.Models.Topic

  initialize: =>
    @page = 1
    @limit = 10

  fetchItems: =>
    @fetch({data: {id: @id, page: @page, limit: @limit}})

  fetchNextPage: (silent=false,successCallback=null) =>
    @page += 1

    payload = {
      add: true
      data: {id: @id, page: @page, limit: @limit}
    }

    if successCallback
      data[success] = successCallback

    if silent
      data[silent] = true

    @fetch(payload)
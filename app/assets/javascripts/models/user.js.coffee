class LL.Models.User extends Backbone.Model
  keepInSync: true
  name: 'user'
  urlRoot: "/api/users"

  initialize: ->
    @following_topics_limit = 10
    @following_topics_page = 1

  following: (model) ->
    if model.get('type') == 'User'
      _.include(@get('following_users'), model.get('_id'))
    else if model.get('type') == 'Topic'
      _.include(@get('following_topics'), model.get('_id'))
    else
      false

  scorePretty: ->
    parseInt @get('score')

  hasRole: (role) ->
    _.include(@get('roles'), role)

  resetFollowingTopics: (limit=null, page=null) =>
    self = @

    data = {id: @get('id')}
    if limit
      @following_topics_limit = limit
      data[limit] = limit
    if page
      @following_topics_page = page
      data[page] = page

    @topics = new LL.Collections.UserFollowingTopics
    @topics.fetch data: data, success: (collection,response) ->
      topics = []
      for topic in response
        topics.push(new LL.Models.Topic(topic))
      self.set('following_topics', topics)
      self.trigger('reset_following_topics')

  loadMoreFollowingTopics: =>
    @following_topics_page += 1
    data = {id: @get('id'), limit: @following_topics_limit, page: @following_topics_page}
    @topics = new LL.Collections.UserFollowingTopics
    @topics.fetch data: data, success: (collection,response) ->
      topics = []
      for topic in response
        topics = self.get('following_topics')
        topics.push(new LL.Models.Topic(topic))
        self.set('following_topics', topics)
        self.trigger('add_following_topics', topic)
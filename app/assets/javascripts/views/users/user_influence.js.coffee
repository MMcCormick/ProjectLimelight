class LL.Views.UserInfluence extends Backbone.View
  template: JST['users/influence']
  el: '#feed'
  id: 'user-influence-page'

  initialize: =>

  render: =>
    $(@el).html(@template())

    @increases = new LL.Collections.InfluenceIncreases()
    @increasesView = new LL.Views.InfluenceIncreasesFull(collection: @increases)
    $('.increases .meat').append(@increasesView.render().el)
    @increases.fetch({data: {id: @user.get('slug'), limit: 10, with_post: true}})

    @influencerTopics = new LL.Collections.InfluencerTopics()
    @influencerTopicsView = new LL.Views.InfluencerTopicsFull(collection: @influencerTopics)
    $('.influencer-topics .meat').append(@influencerTopicsView.render().el)
    @influencerTopics.fetch({data: {id: @user.get('id')}})

    @almostInfluencerTopics = new LL.Collections.AlmostInfluencerTopics()
    @almostInfluencerTopicsView = new LL.Views.AlmostInfluencerTopicsFull(collection: @almostInfluencerTopics)
    $('.almost-influencer-topics .meat').append(@almostInfluencerTopicsView.render().el)
    @almostInfluencerTopics.fetch({data: {id: @user.get('id')}})

    @
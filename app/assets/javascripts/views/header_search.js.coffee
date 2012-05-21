class LL.Views.HeaderSearch extends Backbone.View
  template: JST['header_search']
  className: 'search'

  initialize: ->

  render: =>

    $(@el).html(@template())

    $(@el).find('input').soulmate
      url:            '/autocomplete/search',
      types:          ['user', 'topic'],
      minQueryLength: 2,
      maxResults:     10,
      allowNew:       false,
      selectFirst:    true,
      renderCallback: (term, data, type) ->
        if data['data']['type'] && data['data']['type'].length > 0
          "#{term} <div class='topic-type'>#{data['data']['type']}</div>"
        else
          term

#        if data
      selectCallback: (term, data, type) ->
        window.location = data.data.url

    @
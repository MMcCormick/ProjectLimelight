class LL.Views.TopicSectionList extends Backbone.View
  template: JST['topics/section_list']
  tagName: 'div'
  className: 'section half-section topic-section-list'

  initialize: ->

  render: =>
    $(@el).html(@template(topics: @topics))
    if @topics.length == 0
      $(@el).find('.meat').html('<div class="none">None</div>')
    @
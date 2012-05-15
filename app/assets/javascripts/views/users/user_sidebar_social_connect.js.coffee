class LL.Views.UserSidebarSocialConnect extends Backbone.View
  template: JST['users/sidebar_social_connect']
  tagName: 'section'
  className: 'sidebar-social-connect'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))
    @
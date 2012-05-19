class LL.Views.UserSidebarSocialConnect extends Backbone.View
  template: JST['users/sidebar_social_connect']
  tagName: 'div'
  className: 'section sidebar-social-connect'

  initialize: ->

  render: ->
    $(@el).html(@template(user: @model))
    @
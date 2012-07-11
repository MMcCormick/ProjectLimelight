class LL.Views.SidebarFooter extends Backbone.View
  template: JST['widgets/sidebar_footer']
  className: 'section sidebar-footer'
  tagName: 'div'

  initialize: ->

  render: =>
    if LL.App.current_user
      tweet = "Just signed up to beta test Limelight. It's invite only but you can get access with this code #{LL.App.current_user.get('invite_code').code} @limelight_team"
    else
      tweet = "Check out Limelight! It's a new way to follow the topics you care about. @limelight_team"

    $(@el).html(@template(tweet: tweet))

    @
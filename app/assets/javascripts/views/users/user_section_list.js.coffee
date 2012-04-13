class LL.Views.UserSectionList extends Backbone.View
  template: JST['users/section_list']
  tagName: 'section'
  className: 'half-section user-section-list'

  initialize: ->
    @count = 0

  render: =>
    title = if @count != 1 then "#{@count} Likes" else "#{@count} Like"
    $(@el).html(@template(users: @users, title: title))
    if @users.length == 0
      $(@el).find('.meat').html('<div class="none">None</div>')

    @
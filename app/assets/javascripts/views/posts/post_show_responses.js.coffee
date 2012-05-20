class LL.Views.PostShowResponses extends Backbone.View
  className: 'half-section'

  initialize: ->
    @collection.on('reset', @render)

  render: =>
    console.log @type
    if @type == 'FriendResponses'
      $(@el).addClass('friend-responses').prepend('<div class="top"><h4>Friends Talking</h4></div><input type="text" placeholder="Talk about this!" autocomplete="off" spellcheck="false"><div class="meat"></div>')
    else
      $(@el).addClass('public-responses').prepend("<div class='top'><h4>Other People Talking</h4></div><div class='meat'></div>")

    if @collection.models.length > 0
      for post in @collection.models
        @appendResponse(post)
    else
      $(@el).find('.meat').append('<div class="none">No responses</div>')

    $(@el).fadeIn(200)

    @

  appendResponse: (post) =>
    $(@el).remove('.none')
    response_view = new LL.Views.ResponseTalk(model: post)
    $(@el).find('.meat').append(response_view.render().el)
    @
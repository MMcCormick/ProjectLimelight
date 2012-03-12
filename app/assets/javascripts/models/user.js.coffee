class LL.Models.User extends Backbone.Model
  url: '/api/users'

  initialize: ->

  parse: (resp, xhr) ->
    LL.App.Users.findOrCreate(resp.id, new LL.Models.User(resp))

  following: (model) ->
    if model.constructor.name == 'User'
      _.include(@get('following_users'), model.get('_id'))
    else if model.constructor.name == 'Topic'
      _.include(@get('following_topics'), model.get('_id'))
    else
      false

  scorePretty: ->
    parseInt @get('score')

  bucket: ->
    switch window.location.hostname
      when 'localhost'
        'http://development.img.p-li.me'
      else
        'http://img.p-li.me'

  image_url: (w, h, m, version='current') ->
    if @get('image_versions') == 0
      null
    else if @get('processing_image')
      "#{@bucket()}/users/#{@get('_id')}/#{version}/original.png"
    else
      "#{@bucket()}/users/#{@get('_id')}/#{version}/#{w}_#{h}_#{m}.png"
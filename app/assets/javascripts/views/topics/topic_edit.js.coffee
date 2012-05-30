class LL.Views.TopicEdit extends Backbone.View
  id: 'topic-edit'
  className: 'content-tile modal'

  initialize: ->
    @hasNoUrl = true
    @model.on('change', @render)

  render: =>
    unless @model.get('aliases')
      @model.fetch({data: {id: @model.get('id')}, success: (model, response) -> model.set(response) })
      return @

    self = @

    basic_form = new LL.Views.TopicBasicForm(model: @model)
    $(@el).append(basic_form.render().el)

    image_form = new LL.Views.TopicImageForm(model: @model)
    $(@el).append(image_form.render().el)

    connections = new LL.Collections.TopicConnections
    connection_form = new LL.Views.TopicConnectionForm(model: @model, collection: connections)
    $(@el).append(connection_form.render().el)
    connections.fetch({data: {id: @model.get('id')}})

    alias_form = new LL.Views.TopicAliasForm(model: @model)
    $(@el).append(alias_form.render().el)

    $(@el).find('input.tc-auto').each (i,val) ->
      $(val).soulmate
        url:            '/autocomplete/search',
        types:          ['topic'],
        minQueryLength: 2,
        maxResults:     10,
        allowNew:       true,
        selectFirst:    true,
        renderCallback: (term, data, type) ->
          html = term
          if data.data && data.data.type
            html += "<div class='topic-type'>#{data.data.type}</div>"
          html
        selectCallback: (term, data, type) ->
          name = if data.data then data.data.slug else ''
          self.addTopic($(val), data.term, data.id, name)

    freebase_form = new LL.Views.TopicFreebaseForm(model: @model)
    $(@el).append(freebase_form.render().el)

    @

  addTopic: (target, name, id, slug) =>
    target.val(name).next().val(id)
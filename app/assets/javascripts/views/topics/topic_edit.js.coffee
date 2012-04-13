class LL.Views.TopicEdit extends Backbone.View
  id: 'topic-edit'
  className: 'content-tile modal'

  initialize: ->
    @hasNoUrl = true
    @model.on('change', @render)

  render: =>
    unless @model.get('aliases')
      LL.App.Topics.findOrCreate(@model.get('id'), null, true)
      return @

    self = @

    basic_form = new LL.Views.TopicBasicForm(model: @model)
    $(@el).append(basic_form.render().el)

    connection_form = new LL.Views.TopicConnectionForm(model: @model)
    $(@el).append(connection_form.render().el)

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
          data.id
          name = if data.data then data.data.slug else ''
          self.addTopic($(val), data.term, data.id, name)

    @

  addTopic: (target, name, id, slug) =>
    target.val(name).next().val(id)
class LL.Views.AddMentionForm extends Backbone.View
  template: JST['topics/mention_form']
  tagName: 'div'
  className: 'mention-add-form hide'

  events:
    'click .btn-success': 'addMention'

  initialize: ->

  render: =>
    $(@el).html(@template)
    self = @

    $(@el).find('input.tc-auto').soulmate
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
        console.log $(self.el).find('.tc-auto')
        $(self.el).find('.topic_name').val(data.term).next().val(data.id)

    @

  addMention: (e) =>
    return if $(@el).find('.btn-success').hasClass('disabled')

    e.preventDefault()

    attributes = {
      id: @model.get('id')
      topic_id: $(@el).find('.topic_id').val()
      topic_name: $(@el).find('.topic_name').val()
    }

    self = @
    $.ajax '/api/posts/mentions',
      type: 'post'
      data: attributes
      beforeSend: ->
        $(self.el).find('.btn-success').addClass('disabled').text('Submitting...')
      success: (data) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Topic')
        $(self.el).hide()
        globalSuccess(data)
      error: (jqXHR, textStatus, errorThrown) ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Topic')
        globalError(jqXHR, $(self.el))
      complete: ->
        $(self.el).find('.btn-success').removeClass('disabled').text('Add Topic')
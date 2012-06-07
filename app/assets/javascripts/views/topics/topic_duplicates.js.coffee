class LL.Views.TopicDuplicates extends Backbone.View
  el: $('#topics-c .duplicates-c')

  events:
    'click .check-all': 'checkAll'
    'click .delete': 'destroyTopics'

  initialize: ->

  render: =>

    @

  checkAll: (e) =>
    $(e.currentTarget).parents('.section:first').find('input[type="checkbox"]').each (i,val) ->
      $(val).attr('checked', !$(val).is(':checked'))

  destroyTopics: (e) =>
    destroyed_topics = []
    payload = {
      'ids': []
    }

    radio = $(e.currentTarget).parents('.section:first').find('input:checked[type="radio"]')
    if radio
      payload['merge'] = radio.data('id')

    $(e.currentTarget).parents('.section:first').find('input:checked[type="checkbox"]').each (i,val) ->
      destroyed_topics.push($(val).parents('li:first')[0])
      if !payload['merge'] || $(val).data('id') != payload['merge']
        payload['ids'].push($(val).data('id'))

    if payload['ids'].length > 0
      r = confirm("Are you sure you want to permanently destroy #{payload['ids'].length} topics?!")
      if r == true
        $.ajax '/api/topics',
          {
            type: 'delete'
            data: payload
            dataType: 'json'
            beforeSend: ->
              $(e.currentTarget).addClass('disabled')
            success: (data) ->
              globalSuccess(data)
              $(e.currentTarget).removeClass('disabled')
              $(e.currentTarget).parents('.section:first').find('input').attr('checked', false)
              for topic in destroyed_topics
                $(topic).remove()
            error: (jqXHR, textStatus, errorThrown) ->
              $(e.currentTarget).removeClass('disabled')
              globalError(jqXHR)
            complete: ->
              $(e.currentTarget).removeClass('disabled')
          }
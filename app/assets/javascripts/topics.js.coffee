jQuery ->

  $('.topic-done-b').live 'click', (e) ->
    $('#topic-panel .content').show()
    $('#topic-edit').hide()


  # Creates a qtip with a form to add types to a topic when an .addTypeB is clicked
  $('.addTypeB').livequery ->
    self = $(@)
    self.qtip({
      content: {
        text: 'Loading...',
        ajax: {
          once: true,
          url: self.data("d").newTypeUrl,
          type: 'get',
          success: (data) ->
            self.qtip('option', {
              'content.text': data,
              'content.ajax': false
            })
          error: (data) ->
            self.qtip('option', {
              'content.text': if data.status == 401 then 'You must sign in to see this user\'s info!' else 'Error'
              'content.ajax': false
            })
          "html"
        }
      }
      style: {classes: 'ui-tooltip-shadow', tip: true},
      position: {
        my: 'top right',
        at: 'bottom middle',
        viewport: $(window)
      },
      show: {event: 'click'},
      hide: {event: 'unfocus'}
    })


  spliceString = (str, start, count, stringToInsert) ->
    return str.substring(0, start) + stringToInsert + str.substr(start + count);


  cursor_pos = 0
  current_string = ''
  $('.taggable .content').live 'keyup', (e) ->
#    $(@).val())
    $(@).siblings('.highlighter').html textArea.value = textArea.value.splice(charIndex, 1, "**NEW BIT**");
    `var code = e.which ? e.which : e.keyCode`
    console.log code
    if code == 35 # hash (#) symbol
      #$(@).siblings('.tag_search').show(200).find('input').focus()


  $('.tag_search input').live 'keypress', (e) ->
    `var code = e.which ? e.which : e.keyCode`
    console.log code
    if code == 27 # escape key
      $(@).parent().hide(200)
      $(@).parent().siblings('.taggable').focus()

  $('.tag_search input').livequery ->
    $(@).autocomplete($('#static-data').data('d').topicAutoUrl, {
      minChars: 1,
      matchContains: true,
      autoFill: false,
      searchKey: 'name',
      formatItem: (row, i, max) ->
        return row.formattedItem
      formatMatch: (row, i, max) ->
        return row.name
      formatResult: (row) ->
        return row.name
      })

    $(@).result((event, data, formatted) ->

    )
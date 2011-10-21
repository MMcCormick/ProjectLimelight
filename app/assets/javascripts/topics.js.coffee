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

  # Topic autocomplete for topic connection form
  $('#tc-auto').livequery ->
    self = $(@)
    self.autocomplete $('#static-data').data('d').autocomplete,
    minChars: 2,
    width: 300,
    matchContains: true,
    matchSubset: false,
    autoFill: false,
    selectFirst: false,
    mustMatch: false,
    searchKey: 'term',
    max: 10,
    bucket: false,
    bucketType: ["topic"],
    extraParams: {"types[]":["topic"]},
    dataType: 'json',
    delay: 150,
    formatItem: (row, i, max) ->
      return row.formattedItem;
    formatMatch: (row, i, max) ->
      return row.term;
    formatResult: (row) ->
      return row.term;

    self.result (event, data, formatted) ->
      $('#connection_topic_id').val(data.id)
jQuery ->

  # Freebase
  freebaseLookup = (id) ->
    $.get(
      $('#freebase-ac').data('url')
      freebase_id: id
      (data) ->
        $('#freebase-form-c').html(data.form)

      'json'
    )

  $("#freebase-ac").livequery ->
    $("#freebase-ac")
    .suggest()
    .bind "fb-select", (e, data) ->
       freebaseLookup(data.id)

  $('#freebase-lookup-id').livequery ->
    freebaseLookup($(@).data('id'))

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
  $('.tc-auto').livequery ->
    self = $(@)
    self.autocomplete $('#static-data').data('d').autocomplete,
    minChars: 2,
    width: 450,
    matchContains: true,
    matchSubset: false,
    autoFill: false,
    selectFirst: false,
    mustMatch: false,
    searchKey: 'term',
    buckets: [['topic', 'topic', 'TOPICS']],
    extraParams: {"types":['topic']},
    allowNew: true,
    allowNewName: 'topic',
    allowNewType: 'topic',
    dataType: 'json',
    delay: 100,
    formatItem: (row, i, max) ->
      return row.formattedItem;
    formatMatch: (row, i, max) ->
      return row.term;
    formatResult: (row) ->
      return row.term;

    self.result (event, data, formatted) ->
      self.parent().siblings('#connection_topic_id').val(data.id)

  # TODO: can we combine this and the above? the self.result part is the only difference
  # Topic autocomplete for topic merge form
  $('#tm-auto').livequery ->
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
    buckets: [['topic', 'topic', 'TOPICS']],
    extraParams: {"types":['topic']},
    dataType: 'json',
    delay: 100,
    formatItem: (row, i, max) ->
      return row.formattedItem;
    formatMatch: (row, i, max) ->
      return row.term;
    formatResult: (row) ->
      return row.term;

    self.result (event, data, formatted) ->
      $('#merge-topic-form #target_id').val(data.id)
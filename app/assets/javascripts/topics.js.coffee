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

  $('#freebase-lookup-id span').live 'click', (e) ->
    freebaseLookup($(@).parent().data('id'))

  # Topic autocomplete for topic connection form + new topic form
  $('.tc-auto, #tm-auto').livequery ->
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

  $('.tc-auto').result (event, data, formatted) ->
    id = if data.id then data.id else ''
    $(@).parent().siblings('#connection_topic2_id').val(id)

  $('#tm-auto').result (event, data, formatted) ->
    $('#merge-topic-form #target_id').val(data.id)
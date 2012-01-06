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
  $('.tc-auto, .tc-auto-pic').livequery ->
    self = $(@)
    self.autocomplete $('#static-data').data('d').autocomplete,
    minChars: 2,
    width: 450,
    matchContains: true,
    matchSubset: false,
    autoFill: false,
    selectFirst: true,
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
      console.log(data)
      id = if (data.id && data.id != 0) then data.id else ''
      self.parent().next('.tc-auto-id').val(id)

    $('.tc-auto-pic').result (event, data, formatted) ->
      img_url = '/'+data.data.slug+'/picture?h=150&w=150&m=fillcropmid'
      pickTopic($(@), img_url, data.show)

  #
  # Topic Connection Suggestions
  #
  $("#new_topic_con_sug").bind "keypress", (e) ->
    if (e.keyCode == 13)
      return false

  pickTopic = (ac, img_url, name) ->
    ac.val(name)
    ac.parent().nextAll('.topic-pic:first').html('<img src="'+img_url+'">')
    $('#con-description .t1').html(name) if ac.is('#topic_con_sug_topic1_name')
    $('#con-description .t2').html(name) if ac.is('#topic_con_sug_topic2_name')
    repaint()

  repaint = () ->
    form = $("#new_topic_con_sug")
    desc = $('#con-description')

    oneClass = if (form.find("#topic_con_sug_pull_from").val() == "true") then "pull" else ""
    pull = if (form.find("#topic_con_sug_pull_from").val() == "true") then "will" else "will not"
    $('#con-description .inline-pull').html(pull)

    twoClass = if (form.find("#topic_con_sug_reverse_pull_from").val() == "true") then "pull" else ""
    rev = if (form.find("#topic_con_sug_reverse_pull_from").val() == "true") then "will" else "will not"
    $('#con-description .inline-rev').html(rev)

    if (form.find('#bi').val() == 'true')
      $('#con-description .inline-rev').html(pull)
      oneClass = oneClass + " bi"
      twoClass = "hide"
      revClass = "hide"
    $('.sug-a.one').removeClass('bi pull').addClass(oneClass)
    $('.sug-a.two').removeClass('pull hide').addClass(twoClass)
    $('#reverse-b').removeClass('hide').addClass(revClass)
    if (desc.find('.t1').html() != "" && desc.find('.inline').html() != "" && desc.find('.t2').html() != "")
      desc.removeClass('hide')
    else
      desc.addClass('hide')
    if (desc.find('.t1').html() != "" && desc.find('.inline').html() != "" && desc.find('.t2').html() != "")
      desc.removeClass('hide')
    else
      desc.addClass('hide')

  $('#topic_con_sug_con_id').live 'change', (e) ->
    option = $(@).find('option:selected')
    $("#topic_con_sug_pull_from").val(option.data('d').pull)
    $("#topic_con_sug_reverse_pull_from").val(option.data('d').reverse_pull)
    $("#topic_con_sug_inline").val(option.data('d').inline)
    $('#bi').val(option.data('d').bi)
    $('#con-description .inline').html(option.data('d').inline)
    repaint()

  $('#reverse-b').live 'click', (e) ->
    t1_name = $('#topic_con_sug_topic1_name').val()
    t1_img = $('.topic-pic.one img').attr('src')
    pickTopic($('#topic_con_sug_topic1_name'), $('.topic-pic.two img').attr('src'), $('#topic_con_sug_topic2_name').val())
    pickTopic($('#topic_con_sug_topic2_name'), t1_img, t1_name)

    t1_id = $('#topic_con_sug_topic1_id').val()
    $('#topic_con_sug_topic1_id').val($('#topic_con_sug_topic2_id').val())
    $('#topic_con_sug_topic2_id').val(t1_id)

  $('.sug-a.one').live 'click', (e) ->
    value = if $("#topic_con_sug_pull_from").val() == "false" then true else false
    $("#topic_con_sug_pull_from").val(value)
    repaint()

  $('.sug-a.two').live 'click', (e) ->
    value = if $("#topic_con_sug_reverse_pull_from").val() == "false" then true else false
    $("#topic_con_sug_reverse_pull_from").val(value)
    repaint()
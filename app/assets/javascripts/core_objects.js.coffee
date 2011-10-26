jQuery ->

#  /*
#   * GENERAL OBJECTS
#   */

  $('#contribute, #add_response').live 'click', (e) ->
    target = $($(@).data('target'))
    if target.is(':visible')
      target.slideUp(200)
    else
      target.slideDown(200)
      target.find('#talk_content').focus()


  $('.contributeC .options .option').live 'click', (e) ->
    $(@).parents('.contributeC:first').find('div.form').hide()
    $($(@).data('target')).parents('.form').show()
    $(@).addClass('on').siblings().removeClass('on')

  # Help tooltips on core object submission forms
  $('form.core_object .field').livequery ->
    self = $(@)
    if self.data 'tip'
      self.qtip({
        content:
          self.data 'tip'
        style:
          classes: 'ui-tooltip-red ui-tooltip-shadow'
        position:
          my: 'left center'
          at: 'right center'
      })

  $('.mention').mentionable()

  $('.mention-ooc .auto input').autocomplete($('#static-data').data('d').autocomplete, {
    minChars: 2,
    width: 450,
    matchContains: true,
    matchSubset: false,
    autoFill: false,
    selectFirst: true,
    mustMatch: false,
    searchKey: 'term',
    max: 10,
    bucket: false,
    bucketType: ["topic"],
    extraParams: {"types[]":["topic"]},
    dataType: 'json',
    delay: 150,
    allowNewTopic: true,
    formatItem: (row, i, max) ->
      return row.formattedItem
    formatMatch: (row, i, max) ->
      return row.term
    formatResult: (row) ->
      return row.term
  }).result (event, data, formatted) ->
    parent = $(@).parents('.mention-ooc:first')
    mentions = parent.find('.mentions')
    hidden_data = JSON.parse(parent.find('.hidden_data').val())

    if data.id
      id = data.id
      type = 'existing'
    else
      id = data.term
      type = 'new'

    if mentions.find('.item[data-id="'+id+'"]').length > 0
      createGrowl(false, 'You have already added that topic!', '', 'red')
    else if mentions.find('.item').length >= 4
      createGrowl(false, 'You can only mention 4 topics out of context!', '', 'red')
    else
      if data.data && data.data.image
        image = data.data.image
      else
        image = '/assets/topic_default_25_25.gif'
      mention = $("<div/>").addClass('item hide').attr('data-id', id).attr('data-type', type).html('
        <img width="25px" src="'+image+'" />
        <div class="name">'+data.term+'</div>
        <div class="remove">[x]</div>
      ').appendTo(mentions)
      mention.fadeIn(200)

      hidden_data[type].push(id)

      $(@).val('').blur().focus()
      parent.find('.hidden_data').val(JSON.stringify(hidden_data))

  $('.mention-ooc .remove').live 'click', (e) ->
    mention = $(@).parent()
    hidden_data_field = $(@).parents('.mention-ooc:first').find('.hidden_data')
    hidden_data = JSON.parse(hidden_data_field.val())
    idx = hidden_data[mention.data('type')].indexOf(mention.data('id'));
    if idx != -1
      hidden_data[mention.data('type')].splice(idx,1)
      hidden_data_field.val(JSON.stringify(hidden_data))
    mention.remove()

  # Automatically click the "load more" button if it is visible for more than .5 secs
  $(window).scroll ->
    if !$('#load-more').hasClass('on') && isScrolledIntoView($('#load-more'), true)
      $('#load-more').addClass('on')
      $('#load-more').oneTime(500, 'load_feed_page', ->
        $(@).click()
      )
    else if !isScrolledIntoView($('#load-more'), true)
      $('#load-more').removeClass('on')
      $('#load-more').stopTime('load_feed_page')

  $('#load-more').live 'click', (e) ->
    $(@).addClass('on')
    $(@).html("loading...")

  # Automatically click if visible on page load
  if $('#load-more').length > 0 && isScrolledIntoView($('#load-more'), true)
    $('#load-more').click()

jQuery ->

  $('#contribute, #add_response').live 'click', (e) ->
    if !$logged
      $('#register').click()
      return false

    target = $($(@).data('target'))
    if target.is(':visible')
      target.slideUp(200)
    else
      target.slideDown(200)
      target.find('#talk_content').focus()


  $('.contributeC .options .option').live 'click', (e) ->
    $(@).parents('.contributeC:first').find('div.form').hide()
    $(@).parents('.contributeC:first').find($(@).data('target')).parents('.form').show()
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

  $('.mention').livequery ->
    $(@).mentionable()

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
    buckets: [['topic', 'topic', 'TOPICS']],
    extraParams: {"types":['topic']},
    allowNew: true,
    allowNewName: 'topic',
    allowNewType: 'topic',
    dataType: 'json',
    delay: 100,
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

  $('.mention-ooc .auto input').live 'keypress', (e) ->
    if(window.event)
      key = window.event.keyCode     #IE
    else
      key = e.which     #firefox

    console.log key
    if(key == 35 || key == 64)
      return false

  $('.mention-ooc .remove').live 'click', (e) ->
    mention = $(@).parent()
    hidden_data_field = $(@).parents('.mention-ooc:first').find('.hidden_data')
    hidden_data = JSON.parse(hidden_data_field.val())
    idx = hidden_data[mention.data('type')].indexOf(mention.data('id'));
    if idx != -1
      hidden_data[mention.data('type')].splice(idx,1)
      hidden_data_field.val(JSON.stringify(hidden_data))
    mention.remove()

  # Feed Sort Selection
  $('.feed-sort-select.closed').live 'click', (e) ->
    $(@).prepend($(@).find('.on').parent())
    $(@).children().removeClass('hide')
    $(@).removeClass('closed')

  $('.feed-sort-select:not(.closed)').live 'click', (e) ->
    $(@).find('.opt:not(.on)').parent().addClass('hide')
    $(@).addClass('closed')
    options = []
    $('.feed-sort-select .item').each (i,val) ->
      options[$(val).data('sort')] = val
    $(options).each (i,val) ->
      $('.feed-sort-select').append(val)

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

  # Core object add response
  $('.teaser.list .respond').live 'click', (e) ->
    if !$logged
      $('#register').click()
      return false

    $button = $(@);
    $('.comment_reply:visible').remove();
    $reply = $('#response_form form').clone()
              .find('.comment_reply_cancel').click (e) ->
                $reply.remove()
              .end()
              .appendTo($button.parent())
              .fadeIn(300)
              .find('textarea').focus().end()
    $button.parent().find('#comment_talk_id').attr('value', $button.data('d').id)

  if ($('.teaser.column').length > 0)
    rearrange_feed_columns()

  # re-calculate column view on window resize
  $(window).resize ->
    $(window).stopTime('resize-column-feed')
    $(window).oneTime 500, "resize-column-feed", ->
      rearrange_feed_columns()

  $('.teaser.column,.teaser.grid').livequery ->
    self = $(@)
    $(@).qtip({
      content: {
        text: self.find('.controlsC')
      }
      events: {
        show: (event, api) ->
          $('.teaser.column').qtip('hide')
      }
      position: {
        my: 'left top'
        at: 'right top'
        adjust: {
           y: 8
        }
        viewport: $(window)
      }
      style: {
        classes: 'ui-tooltip-light ui-tooltip-shadow fab' # fab = feed action box :)
        tip: {
           mimic: 'center'
           offset: 8
           width: 8
           height: 8
        }
      }
      show: {delay: 500}
      hide: {delay: 200, fixed: true}
    });
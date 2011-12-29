jQuery ->

  ####
  # CONTRIBUTE FORM
  ####

  resetContribute = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.attr('action', talkForm.data('old-action'))
    talkForm.find('#talk_content').attr('name', 'talk[content]').parents('.lClear:first').addClass('required').find('label').text('What do you want to talk about?')
    talkForm.find('#talk_content_raw').attr('name', 'talk[content_raw]')
    talkForm.find('#talk_ooc_mentions').attr('name', 'talk[ooc_mentions]')

  $('#contribute, #add_response').live 'click', (e) ->
    if !$logged
      $('#register').click()
      return false

    target = $($(@).data('target'))
    if target.is(':visible')
      target.slideUp(200)
    else
      target.slideDown(200)

  # handle option choices on contribute form (clicking add picture/video/link)
  $('.contributeC .options .option').live 'click', (e) ->
    $self = $(@)
    parentForm = $self.parents('.contributeC:first')

    if ($self.hasClass('on'))
      return

    $self.siblings('.option').fadeOut 100, ->
      fade = if $self.hasClass 'picture' then 1 else 150
      $self.addClass 'on', fade, ->
        $self.find('.cancel').fadeIn(100)

        if $self.hasClass 'picture'
          parentForm.find('.picture_options').fadeIn 100
        else if $self.hasClass 'link'
          parentForm.find('.url.link').fadeIn 100

  # handle option cancel on contribute form
  $('.contributeC .options .option .cancel').live 'click', (e) ->
    $self = $(@).parent()
    $('.contributeC .picture_options,.contributeC .url.picture,.contributeC .url.video,.contributeC .url.link').fadeOut 150

    $('.contributeC .main_content .shared').fadeOut 400, ->
      $(@).remove()
      resetContribute($self.parents('.contributeC:first'))

    $self.find('.cancel').fadeOut 150, ->
      $self.removeClass 'on', 150, ->
        $self.siblings('.option').fadeIn(100)

  setContributeToPicture = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_picture').attr('action'))
    talkForm.find('#talk_content').attr('name', 'picture[content]').parents('.lClear:first').removeClass('required').find('label').text('Say something about this picture...')
    talkForm.find('#talk_content_raw').attr('name', 'picture[content_raw]')
    talkForm.find('#talk_ooc_mentions').attr('name', 'picture[ooc_mentions]')

  setContributeToVideo = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_video').attr('action'))
    talkForm.find('#talk_content').attr('name', 'video[content]').parents('.lClear:first').removeClass('required').find('label').text('Say something about this video...')
    talkForm.find('#talk_content_raw').attr('name', 'video[content_raw]')
    talkForm.find('#talk_ooc_mentions').attr('name', 'video[ooc_mentions]')

  setContributeToLink = (targetForm) ->
    talkForm = targetForm.find('#new_talk')
    talkForm.data('old-action', talkForm.attr('action'))
    talkForm.attr('action', targetForm.find('#new_link').attr('action'))
    talkForm.find('#talk_content').attr('name', 'link[content]').parents('.lClear:first').removeClass('required').find('label').text('Say something about this link...')
    talkForm.find('#talk_content_raw').attr('name', 'link[content_raw]')
    talkForm.find('#talk_ooc_mentions').attr('name', 'link[ooc_mentions]')

  # fetch data from a link and update the contribute form
  $('.contributeC #link_fetch').live 'change', (e) ->
    self = $(@)
    if $.trim(self.val()) == ''
      return

    $.get(
      $('#static-data').data('d').fetchEmbedUrl
      url: self.val()
      (data) ->
        parentForm = self.parents('.contributeC:first')

        if data.embedly.oembed.type == 'video'
          clone = parentForm.find('.new_video').find('.shared').clone()
          provider = data.embedly.provider_name
          video_id = data.video_id
          html = data.video_html
          target = clone.find('.preview')

          if html
            target.html(html)
          else
            target.html('<div class="none">Sorry, no video embed available.')

          clone.find('#video_source_url').val(data.embedly.url)
          clone.find('#video_title').focus().val(data.embedly.title)
          clone.find('#video_source_name').val(provider)
          clone.find('#video_source_video_id').val(video_id)
          setContributeToVideo(parentForm)

        else if data.embedly.oembed.type == 'photo'
          clone = parentForm.find('.new_picture').find('.shared').clone()
          clone.find('#picture_source_url').val(data.embedly.url)
          clone.find('#picture_source_name').val(data.embedly.provider_name)
          setContributeToPicture(parentForm)
        else
          clone = parentForm.find('.new_link').find('.shared').clone()
          clone.find('#link_title').focus().val(data.embedly.title)
          clone.find('#link_source_url').val(data.embedly.url)
          clone.find('#link_source_name').val(data.embedly.provider_name)
          setContributeToLink(parentForm)

        parentForm.find('.main_content').prepend(clone)
        clone.fadeIn 150
        self.val('').blur().parent().fadeOut 150

        if data.embedly.images.length > 0
          target = clone.find('.preview .images')
          target.html('')

          for image in data.embedly.images
            target.append("<img src='"+image.url+"' />")

          target.find('img:not(:first)').hide()

          clone.find('.remote_image_url').val(target.find('img:first').attr('src'))

          if data.embedly.images.length > 1
            clone.find('.switcher').removeClass('hide')

      'json'
    )

  # update after the user uploads their own image
  $('.contribute_picture_image_data').live 'click', ->
    params = $(@).data('params')
    parentForm = $(@).parents('.contributeC:first')
    pictureForm = parentForm.find('.new_picture')
    clone = pictureForm.find('.shared').clone()
    parentForm.find('.main_content').prepend(clone)
    target = clone.find('.preview .images')

    clone.find('.image_upload_cache').val(params.image_location)
    target.html('<img src="'+params.image_location+'" />')

    parentForm.find('.picture_options').fadeOut 150
    clone.fadeIn 150

    $('#picture_fetch').val('').blur().parent().fadeOut(150)
    setContributeToPicture(parentForm)

  $('.contributeC .switcher .left').live 'click', (e) ->
    target = $(@).parents('.shared:first').find('.preview img:visible').hide()
    if target.prev().is('img')
      found = target.prev()
    else
      found = $(@).parents('.shared:first').find('.preview img:last')

    $(@).parents('.shared:first').find('.remote_image_url').val(found.attr('src'))
    found.show()

  $('.contributeC .switcher .right').live 'click', (e) ->
    target = $(@).parents('.shared:first').find('.preview img:visible').hide()
    if target.next().is('img')
      found = target.next()
    else
      found = $(@).parents('.shared:first').find('.preview img:first')

    $(@).parents('.shared:first').find('.remote_image_url').val(found.attr('src'))
    found.show()

  $('.contributeC .shared .cancel').live 'click', (e) ->
    $(@).parents('.contributeC:first').find('.option:visible .cancel').click()

  $('.contributeC .actions .cancel').live 'click', (e) ->
    $(@).parents('.contributeC:first').slideUp(150)

  $('.contributeC .connect_twitter').live 'click', (e) ->
    $self = $(@)
    $.colorbox({
      title:false,
      transition: "elastic",
      speed: 100,
      opacity: '.95',
      fixed: true,
      html: '
        <h3 style="margin: 10px; width: 250px">
          You need to visit Twitter to authenticate.
          After authenticating you will need to re-enter your post.
          You only need to connect to twitter once!
        </h3>
        <div style="margin: 0 0 10px 10px;">
          <a href="'+$self.data('auth')+'">Continue Authenticating</a>
        </div>
      '
    })

  $('.contributeC .tweet input').live 'click', (e) ->
    target = $(@).parents('form:first').find('.tweet_content')
    target.toggle()

  # Title character counter
  $('.contributeC .title .mention').livequery (e) ->
    $(@).charCount({
      allowed: 125,
      warning: 20
    })

  # Content character counter
  $('.contributeC .talk_content .mention').livequery (e) ->
    $(@).charCount({
      allowed: 280,
      warning: 30
    })

  ####
  # END CONTRIBUTE FORM
  ####

  # mention boxes
  $('.mention').livequery ->
    $(@).mentionable()

  # out of context mentions on contribute form
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
    else if mentions.find('.item').length >= 3
      createGrowl(false, 'You can only mention 3 topics out of context!', '', 'red')
    else
      if data.data && data.data.image
        image = data.data.image
      else
        image = '/assets/topic_default_25_25.gif'
      mention = $("<div/>").addClass('item hide').attr('data-id', id).attr('data-type', type).html('
        <div class="remove">[x]</div>
        <div class="name" title="'+data.term+'">'+data.term+'</div>
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
              .find('textarea').end()
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
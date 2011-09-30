jQuery ->

#  /*
#   * GENERAL OBJECTS
#   */

#  // Contribute form
#  $('#contributeC .nav > div').live('click', function() {
#    $(this).addClass('on').siblings().removeClass('on');
#    $('#contributeC form').hide();
#    $($(this).data('target')).show();
#    $.colorbox.resize();
#  })

  $('#contribute').live 'click', (e) ->
    if $('#contributeC').is(':visible')
      $('#contributeC').slideUp(200)
    else
      $('#contributeC').slideDown(200)


  $('#contributeC .option').live 'click', (e) ->
    $('#contributeC div.form').hide()
    $($(@).data('target')).parents('.form').show()
    $(@).addClass('on').siblings().removeClass('on')

  # Topic tagger for live updating of inlined and separately entered topics
  $('.tagDisplay').livequery ->
    # Sets self to the element with class tagDisplay
    self = $(@)
    tagField = self.find('.formTagged')
    contentField = self.siblings('textArea')
    self.parent().typing({
      stop: (e) ->
        # Finds all topic tags, unfortunately with [# still at the beginning
        # This is due to javascript's lack of a ?<= operator for regexes
        tags = contentField.val().match(/(?=\[#)(.*?)(?=\])/g)
        tagText = ''
        displayText = ''

        # Insert hand-entered (non-inlined) topics into the tagText
        self.find('input:text[value!=""]').not('.inlined').each ->
          tagText = tagText + $.trim($(this).val()) + ", "
        # Find inlined topics, clear their contents and remove the class 'inlined'
        self.find('.inlined').val('').removeClass('inlined')
        # If there are inline tags
        if tags
          for tag in tags
            # Removes the first two characters '[#' and trims whitespace
            tag = $.trim(tag.substr(2))

            #TODO: make sure the duplicate case below does not fire when there are no duplicates
            # If the tag already exists in the display area
            if self.find('input:text[value="' + tag + '"]').addClass('inlined').length > 0
              console.log('duplicate')
            # If there are no more topic slots left
            else if self.children('input:text[value=""]:eq(0)').size() == 0
              createGrowl(false, 'You can only tag ' + self.children('input:text').length + ' topics!', 'Error', 'red')
            else
              # Adds the tag to the tagText
              tagText = tagText + tag + ", "
              # Finds the first empty input in displayField and places the new topic there
              self.find('input:text[value=""]:eq(0)').addClass('inlined').val(tag)

        # Removes trailing comma and space
        tagText = tagText.slice(0, -2)
        tagField.val(tagText)
      delay: 400
    })

  $('form.core_object .field').livequery ->
    self = $(@)
    self.qtip({
      content:
        self.data 'tip'
      style:
        classes: 'ui-tooltip-red ui-tooltip-shadow'
      position:
        my: 'left center'
        at: 'right center'
    })
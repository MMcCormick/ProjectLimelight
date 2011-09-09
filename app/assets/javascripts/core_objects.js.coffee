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

#  // Top search
#  $('#search input').autocomplete($('#static-data').data('d').oSearchUrl, {
#    minChars: 2,
#    width: 245,
#    matchContains: true,
#    autoFill: false,
#    searchKey: 'name',
#    formatItem: function(row, i, max) {
#      console.log(row);
#      return row.name;
#    },
#    formatMatch: function(row, i, max) {
#      return row.name;
#    },
#    formatResult: function(row) {
#      return row.name;
#    }
#  });
#
#  // Finishing editing an object
#  $('.edit-panel .cancel').live('click', function() {
#    var parent = $(this).parent().parent();
#
#    // Remove the edit-panel
#    $(this).parent().remove();
#
#    // Remove the edit class and restore the original content
#    parent.html(parent.data('original'));
#
#    resetPage(true);
#  })
#
#  // Enable the mouse score buttons on objects
#  $('.oS').live('mousedown',
#          function(e) {
#            $('.oS').removeClass('scoring');
#            if (e.which == 1) {
#              $(this).oneTime(500, 'show-floating-scorebox', function() {
#                $('.oS').removeClass('scoring');
#                $(this).addClass('scoring');
#                var $scoreBox = $(this).find('.scoreC').clone();
#                $scoreBox.find('.u').removeClass('thumbs-up-icon').addClass('thumbs-up-small-icon');
#                $scoreBox.find('.d').removeClass('thumbs-down-icon').addClass('thumbs-down-small-icon');
#                $('#mouse-score').data('id', $scoreBox.data('id')).html($scoreBox.html()).css({top: e.pageY - 32 + 'px', left: e.pageX - 15 + 'px'}).fadeIn(250);
#              })
#              return false;
#            }
#          }).live('mouseup', function() {
#            $('.oS').stopTime('show-floating-scorebox');
#            $('.oS').removeClass('scoring');
#            $('#mouse-score').fadeOut(200, function() {
#              $(this).html('');
#            });
#          })
#  $('#mouse-score .s, #mouse-score .v').live('click', function() {
#    $(this).parent().oneTime(1500, 'hide-score-box', function() {
#      $('.oS').removeClass('scoring');
#      $(this).fadeOut(500, function () {
#        $(this).html()
#      });
#    })
#  })
#
#  // Fetch the embedly information on enabled URL fields
#  $('input.embedUrl').live('paste', function() {
#    console.log('changed!');
#    var $self = $(this);
#    $self.oneTime(200, 'fetch-embed', function() {
#      $.post($('#static-data').data('d').fetchEmbedUrl, {'url':$self.val()}, function(data) {
#        console.log(data);
#        var $form = $self.parents('form');
#        $form.find('.description').val(data[0].description);
#        $form.find('.mediaUrl').val(data[0].html);
#        $form.find('.provider').val(data[0].provider);
#        $form.find('.title').val(data[0].title);
#        $form.find('.embed .media').html(data[0].html);
#      }, 'json')
#    });
#  })
#
#  $('.scrollTop').live('click', function() {
#    $(window).scrollTo(0, 500);
#  })
#
#  // Feed Filters
#  $('#feed-filters .opt').live('click', function () {
#    $parent = $(this).parent().parent().parent()
#    if ($parent.hasClass('feed-display'))
#    {
#      $(this).toggleClass('on')
#    }
#    else
#    {
#      $parent.find('.opt').removeClass('on')
#      $(this).addClass('on')
#    }
#    $payload = {'display':[]}
#    $payload['sort'] = $('#feed-filters .feed-sort .opt.on').data('d')
#    $payload['layout'] = $('#feed-filters .feed-layout .opt.on').data('d')
#    $('#feed-filters .feed-display .opt.on').each(function(i, val) {
#      $payload['display'].push($(val).data('d'))
#    })
#    $.post($('#feed-filters').data('url'), $payload, function(response) {
#      console.log(response)
#    })
#  })
#  // Sort dropdown
#  $('.feed-sort ul').live({
#    mouseenter: function() {
#      $(this).find('li').show();
#    },
#    mouseleave: function() {
#      $(this).find('.opt:not(.on)').parent().hide();
#    }
#  })
#})
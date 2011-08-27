$(function() {

  /*
   * GENERAL OBJECTS
   */

  // Contribute form
  $('#contributeC .nav > div').live('click', function() {
    $(this).addClass('on').siblings().removeClass('on');
    $('#contributeC form').hide();
    $($(this).data('target')).show();
    $.colorbox.resize();
  })

  // Top search
  $('#search input').autocomplete($('#static-data').data('d').oSearchUrl, {
    minChars: 2,
    width: 245,
    matchContains: true,
    autoFill: false,
    searchKey: 'name',
    formatItem: function(row, i, max) {
      console.log(row);
      return row.name;
    },
    formatMatch: function(row, i, max) {
      return row.name;
    },
    formatResult: function(row) {
      return row.name;
    }
  });

  // Finishing editing an object
  $('.edit-panel .cancel').live('click', function() {
    var parent = $(this).parent().parent();

    // Remove the edit-panel
    $(this).parent().remove();

    // Remove the edit class and restore the original content
    parent.html(parent.data('original'));

    resetPage(true);
  })

  // Enable the mouse score buttons on objects
  $('.oS').live('mousedown',
          function(e) {
            $('.oS').removeClass('scoring');
            if (e.which == 1) {
              $(this).oneTime(500, 'show-floating-scorebox', function() {
                $('.oS').removeClass('scoring');
                $(this).addClass('scoring');
                var $scoreBox = $(this).find('.scoreC').clone();
                $scoreBox.find('.u').removeClass('thumbs-up-icon').addClass('thumbs-up-small-icon');
                $scoreBox.find('.d').removeClass('thumbs-down-icon').addClass('thumbs-down-small-icon');
                $('#mouse-score').data('id', $scoreBox.data('id')).html($scoreBox.html()).css({top: e.pageY - 32 + 'px', left: e.pageX - 15 + 'px'}).fadeIn(250);
              })
              return false;
            }
          }).live('mouseup', function() {
            $('.oS').stopTime('show-floating-scorebox');
            $('.oS').removeClass('scoring');
            $('#mouse-score').fadeOut(200, function() {
              $(this).html('');
            });
          })
  $('#mouse-score .s, #mouse-score .v').live('click', function() {
    $(this).parent().oneTime(1500, 'hide-score-box', function() {
      $('.oS').removeClass('scoring');
      $(this).fadeOut(500, function () {
        $(this).html()
      });
    })
  })

  // Fetch the embedly information on enabled URL fields
  $('input.embedUrl').live('paste', function() {
    console.log('changed!');
    var $self = $(this);
    $self.oneTime(200, 'fetch-embed', function() {
      $.post($('#static-data').data('d').fetchEmbedUrl, {'url':$self.val()}, function(data) {
        console.log(data);
        var $form = $self.parents('form');
        $form.find('.description').val(data[0].description);
        $form.find('.mediaUrl').val(data[0].html);
        $form.find('.provider').val(data[0].provider);
        $form.find('.title').val(data[0].title);
        $form.find('.embed .media').html(data[0].html);
      }, 'json')
    });
  })

  $('.scrollTop').live('click', function() {
    $(window).scrollTo(0, 500);
  })

//    function split(val) {
//        return val.split(/@\s*/);
//    }
//
//    function extractLast(term) {
//        return split(term).pop();
//    }
//
//    var $mention = '';
//    $('.o-linkable').livequery(function() {
//        $(this)
//            .after('<input type="hidden" class="o-mentions" name="mentions" />')
//            .after('<input type="text" class="o-mentions-ac" />');
//    })
//    $('.o-linkable').live('keypress', function(e) {
//        // @ symbol
//        if (e.which == 64)
//        {
//            $mention = '';
//            $(this).addClass('mentioning');
//            return;
//        }
//        // Spacebar
//        else if (e.which == 32)
//        {
//            $mention = '';
//            $(this).removeClass('mentioning');
//        }
//        // Backspace
//        else if (e.which == 8)
//        {
//            var selection = $(this).getSelection();
//            var selStart  = (selection.length) ? selection.start : selection.start - 1;
//            var selEnd    = selection.end;
//            if ($(this).val().slice(selStart, selEnd) == '@')
//            {
//                $mention = '';
//                $(this).removeClass('mentioning');
//            }
//        }
//
//        if ($(this).hasClass('mentioning'))
//        {
//            if (e.which == 8)
//            {
//                $mention =  $mention.substr(0, $mention.length-1);
//                console.log($mention);
//                $(this).next().val($mention).search();
//            }
//            else if (((e.which >= 65 && e.which <= 90) || (e.which >= 97 && e.which <= 122) || (e.which >= 48 && e.which <= 57)))
//            {
//                $mention += String.fromCharCode(e.which);
//                $(this).next().val($mention).search();
//            }
//        }
//    })
//    $(".o-mentions-ac").livequery(function() {
//        $(this).autocomplete($('#static-data').data('d').oSearchUrl, {
//            minChars: 2,
//            width: 245,
//            matchContains: true,
//            autoFill: false,
//            searchKey: 'name',
//            formatItem: function(row, i, max) {
//                console.log(row);
//                return row.name;
//            },
//            formatMatch: function(row, i, max) {
//                return row.name;
//            },
//            formatResult: function(row) {
//                return row.name;
//            }
//        });
//    })
})
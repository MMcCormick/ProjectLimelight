$(function() {

  /*
   * LISTS
   */

  $('.list-createB').colorbox({title:"Create a New List", transition: "none", opacity: .5, href: function() {
    return $(this).attr('href') + '.ajax'
  }});

  /*
   * COMMENTS
   */

  // Show the comment reply box
  $('.comment .reply-show').live('click', function() {
    if (!$logged)
      $('#register').click();
      return false;

    var $button = $(this);
    $('.comment_reply:visible').remove();
    var $reply = $('.comment_reply').clone()
            .find('.comment_reply_cancel').click(
            function() {
              $reply.remove();
            }).end()
            .appendTo($button.parent().parent())
            .fadeIn(300)
            .find('textarea').focus().end();
    // add the comment parent id to the hidden form
    $button.parents('.comment:first').find('#comment_parent_id').attr('value', $button.data('d').id);
    $button.parents('.comment:first').find('#comment_talk_id').attr('value', $button.parents('.comment-thread:first').data('d').talk_id);
  });

  /*
   * User and Topic Hover Tabs - QTips
   */
  $('.ulink, .tlink').livequery(function() {
    $(this).each(function() {
      var $self = $(this);
      $self.qtip({
        content: {
          text: 'Loading...',
          ajax: {
            once: true,
            url: $self.data('d').url,
            type: 'get',
            success: function(data) {
              // If self is a ulink, set target to ulink with the given public id, else tlink
              var target = $self.hasClass('ulink') ? $('.ulink[data-pid="'+$self.data('pid')+'"]') : $('.tlink[data-pid="'+$self.data('pid')+'"]');
              target.qtip('option', {
                'content.text': data,
                'content.ajax': false
              });
            },
            error: function(data) {
              // If self is a ulink, set target to ulink with the given public id, else tlink
              var target = $self.hasClass('ulink') ? $('.ulink[data-pid="'+$self.data('pid')+'"]') : $('.tlink[data-pid="'+$self.data('pid')+'"]');
              target.qtip('option', {
                'content.text': data.status == 401 ? 'You must sign in to see this user\'s info!' : 'Error',
                'content.ajax': false
              });
            }
          }
        },
        style: {classes: 'userHover ui-tooltip-shadow ui-tooltip-light', tip: true},
        position: {
          my: 'left middle',
          at: 'right middle',
          viewport: $(window)
        },
        show: {delay: 1000},
        hide: {delay: 300, fixed: true}
      })
    })
  })

  // Static flashes
  if ($('#flash_notice').length > 0)
  {
    createGrowl(false, $('#flash_notice').text(), '', 'green');
  }


  /*
   * FEEDS
   */

  // Hover Class (allows keyboard shortcuts to control hover as well as mouse)
  $('.teaser').live({
    mouseenter: function() {
      if (!$('body').hasClass('shortcut-on')) {
        $('.teaser').removeClass('hover');
        $(this).addClass('hover');
        if (feedLastInRow($(this)))
        {
          $(this).addClass('left');
        }
      }
    },
    mouseleave: function() {
      if (!$('body').hasClass('shortcut-on')) {
        $('.teaser').removeClass('hover left');
      }
    }
  })

  $('.scrollTop').live('click', function() {
    $(window).scrollTo('0', 300);
  })

  $('body').mousemove(function() {
    $(this).removeClass('shortcut-on')
  })

  $('#feed-filters .feed-sort .opt').live('click', function() {
    if (!$(this).hasClass('on')) {
      $('#feed-filters .feed-sort .opt').removeClass('on');
      $(this).addClass('on');
      updateFeedFilters();
    }
  })

  $('#feed-filters .feed-display .opt').live('click', function() {
    $(this).toggleClass('on');
    if ($('#feed-filters .feed-display .opt.on').length == 0) {
      $('#feed-filters .feed-display .opt').addClass('on');
    }
    updateFeedFilters();
  })

  $('#feed-filters .feed-display .opt').live('dblclick', function() {
    $('#feed-filters .feed-display .opt').removeClass('on');
    $(this).addClass('on');
    updateFeedFilters();
  })

  $('#feed-filters .feed-layout .opt div').live('click', function() {
    if (!$(this).hasClass('on')) {
      $('#feed-filters .feed-layout .opt div').removeClass('on');
      $(this).addClass('on');
      updateFeedFilters();
    }
  })

  function updateFeedFilters()
  {
    $('#feed-filters').stopTime().oneTime(500, 'reload_feed', function() {
      var payload = {sort: {}, display: [], layout: ''}
      payload['sort'] = $('#feed-filters .feed-sort .opt.on').data('d')
      $('#feed-filters .feed-display .opt.on').each(function(i,val) {
        payload['display'].push($(val).data('d'));
      })
      payload['layout'] = $('#feed-filters .feed-layout .opt div.on').data('d')
      console.log($('#static-data').data('d'));
      $.ajax({
        url: $('#static-data').data('d').feedFiltersUpdate,
        dataType: 'json',
        data: payload,
        type: 'PUT',
        success: function(data) {
          $('#feed-reload').click();
        }
      })
    })
  }

  /*
   * HINTS
   */
  $('#hints #shortcuts').livequery(function() {
    $(this).qtip({
      content: {
        text: '<div>navigation: up, down, left, right</div>' +
                '<div>go to post: enter</div>' +
                '<div>vote up: shift+up</div>' +
                '<div>vote down: shift+down</div>' +
                '<div>favorite: f</div>' +
                '<div>repost: r</div>' +
                '<div>share: s</div>'
      },
      style: {classes: 'ui-tooltip-shadow ui-tooltip-light', tip: true},
      position: {
        my: 'left middle',
        at: 'right middle',
        viewport: $(window)
      },
      show: {delay: 300},
      hide: {delay: 150, fixed: true}
    })
  })

  /*
   * PICTURES
   */

  // Image Lightboxes

  $('.lbImg').livequery(function() {
    var $src = $(this).attr('src'),
            $newSrc = '/slir/w1200-h1200';

    $.each($src.split('/'), function(index, val) {
      if (index >= 3) {
        $newSrc += '/' + val;
      }
    })

    $(this).colorbox({href: $newSrc, photo: true, title: $('#page_header .titleC').text()});
  })

  /*
   * SEARCH
   */

  $('#search input').live('focus', function() {
    $(this).animate({'width':'300px'}, 200);
  }).live('blur', function() {
    $(this).animate({'width':'150px'}, 200);
  }).autocomplete($('#static-data').data('d').autocomplete, {
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
    bucketType: ["topic", "user"],
    extraParams: {"types[]":["topic", "user"]},
    dataType: 'json',
    delay: 150,
    formatItem: function(row, i, max) {
      return row.formattedItem;
    },
    formatMatch: function(row, i, max) {
      return row.term;
    },
    formatResult: function(row) {
      return row.term;
    }
  }).result(function(event, data, formatted) {
    if (data.bucketType == 'user')
    {
      window.location = '/users/'+data.term
    }
    else if (data.bucketType == 'topic')
    {
      window.location = '/'+data.data.slug
    }
  });

  /*
   * SHORTCUTS
   */

  // Shortcut keycode mapping
  var $sc = {'up':38, 'down':40, 'left':37, 'right':39, 'fav':70, 'repost':82, 'share':83, 'talk':84, 'goTo':13}

  // Prevents default browser scroll actions for directional keys
  $(document).keydown(function(e) {
    // If we are focused on a text field or text area
    if ($(e.target).is('input, textarea, select')) {
      return;
    }

    var $code = e.which ? e.which : e.keyCode;
    if ($code == $sc.up || $code == $sc.down || $code == $sc.left || $code == $sc.right) {
      e.preventDefault();
    }
  })

  // TODO: have this account for the right sidebar
  function feedLastInRow(elem)
  {
    if ($('body').width()-elem.width()-elem.offset().left < 65)
    {
      return true
    }
    return false
  }

  // On keyup
  $(document).keyup(function(e) {

    // If we are focused on a text field or text area
    if ($(e.target).is('input, textarea, select')) {
      return;
    }

    var $code = e.which ? e.which : e.keyCode;
    var $newHover = false;

    switch (true) {
      // Nav / Hover Controls
      case (!e.shiftKey && ($code == $sc.up || $code == $sc.down || $code == $sc.left || $code == $sc.right)):
        $('body').addClass('shortcut-on');

        var target = $('.teaser.hover'),
        hoverClass = 'hover';
        $('.teaser.grid,.teaser.column').qtip('hide')

        // If  teaser is hovered
        if (target.length > 0) {
          // Column view
          if (target.hasClass('column')) {
            var column_num;

            // Left or Right
            if ($code == $sc.left || $code == $sc.right) {
              numcols = $('#core-feed').data('numcols');
              current_offset = target.position().top;

              if ($code == $sc.left) {
                column_num = (target.data('column') - 1);
                if (column_num == -1) { column_num = numcols - 1 }
              }
              else { column_num = (target.data('column') + 1) % numcols }

              best_dif = 5000;
              var best_obj;
              $('.teaser.column.[data-column="'+column_num+'"]').each(function(index, teaser) {
                if ($(this).position().top + $(this).height() > current_offset) {
                  middle_dif = Math.abs(current_offset + (target.height() / 2) - ($(this).position().top + ($(this).height() / 2)));

                  if (middle_dif < best_dif) {
                    target.removeClass(hoverClass);
                    best_dif = middle_dif;
                    best_obj = $(this);
                  }
                  else {
                    best_obj.addClass(hoverClass).qtip('show');
                    return false;
                  }
                }
              });
              // if no teaser was found in the correct column, select the last teaser of the column
              if ($('.teaser.hover').length == 0) {
                $('.teaser.column.[data-column="'+column_num+'"]').last().addClass(hoverClass).qtip('show');
              }
            }

            // Up
            else if ($code == $sc.up) {
              column_num = target.data('column');
              if (target.prevAll('.teaser.column.[data-column="'+column_num+'"]').length > 0) {
                target.removeClass(hoverClass).prevAll('.teaser.column.[data-column="'+column_num+'"]').first().addClass(hoverClass).qtip('show')
              }
            }
            // Down
            else if ($code == $sc.down) {
              column_num = target.data('column');
              if (target.nextAll('.teaser.column.[data-column="'+column_num+'"]').length > 0) {
                target.removeClass(hoverClass).nextAll('.teaser.column.[data-column="'+column_num+'"]').first().addClass(hoverClass).qtip('show')
              }
            }
          }

          // Grid + List view
          else {
            extra = parseInt($('.teaser.grid').css('margin-left').replace("px", "")) * 2 + parseInt($('.teaser.grid').css('border-left-width').replace("px", "")) * 2;

            // If first element is hovered and left or up is pressed
            if (($code == $sc.up || $code == $sc.left) && $('.teaser:first').hasClass(hoverClass)) {
              $('.teaser:first').qtip('show');
              return false;
            }
            // Go to previous
            if (target.hasClass('list') && ($code == $sc.up || $code == $sc.left) ||
                    target.hasClass('grid') && ($code == $sc.left)) {
              if (feedLastInRow(target.prev()))
                hoverClass += ' left';

              target.removeClass(hoverClass).prev().addClass(hoverClass).qtip('show');
            }
            // Go to next
            else if (target.hasClass('list') && ($code == $sc.down || $code == $sc.right) ||
                    target.hasClass('grid') && ($code == $sc.right)) {
              if (feedLastInRow(target.next()))
                hoverClass += ' left';

              target.removeClass(hoverClass).next().addClass(hoverClass).qtip('show');
            }

            // Jump up a row (for Grid View)
            else if (target.hasClass('grid') && ($code == $sc.up)) {
              target.removeClass(hoverClass).prevAll().eq(($('#core-feed').width()) / ($('.teaser.grid').width() + extra) - 1).addClass(hoverClass).qtip('show');
              if ($('.teaser.hover').length == 0) {
                $newHover = true;
              }
            }
            // Jump down a row (for Grid View)
            else if (target.hasClass('grid') && ($code == $sc.down)) {
              console.log($('#core-feed').width());
              console.log($('.teaser.grid').width());
              target.removeClass(hoverClass).nextAll().eq(($('#core-feed').width()) / ($('.teaser.grid').width() + extra) - 1).addClass(hoverClass).qtip('show');
            }
          }
        }

        else {
          $newHover = true;
        }

        // If the app needs to pick a new teaser to hover
        if ($newHover) {
          if ($('.teaser:first:onScreen').length > 0) {
            $('.teaser:first').addClass(hoverClass).qtip('show')
          }
          else if ($('.teaser:onScreen:first').hasClass('grid')) {
            $('.teaser:onScreen:first').nextAll().eq($('#core-feed').width() / $('.teaser.grid').width() - 1).addClass(hoverClass).qtip('show')
          }
          else {
            $('.teaser:onScreen:first').next().addClass(hoverClass).qtip('show');
          }
        }

        // If the new hovered teaser is out of view, adjust viewport according to keystroke
        if (!isScrolledIntoView($('.teaser.hover'), true, false, true)) {
          $(window).scrollTo($('.teaser.hover'), 300, {offset: -100});
        }
      break;

      // Score Up
      case (e.shiftKey && $code == $sc.up):
        $('.teaser.hover').find('.voteB.up, .unvoteB.up').click();
      break;

      // Score Down
      case (e.shiftKey && $code == $sc.down):
        $('.teaser.hover').find('.voteB.down, .unvoteB.down').click();
      break;

      // Favorite
      case (e.shiftKey && $code == $sc.fav):
        $('.teaser.hover').find('.favB, .unfavB').click();
      break;

      // Repost
      case (e.shiftKey && $code == $sc.repost):
        $('.teaser.hover').find('.repostB, .unrepostB').click();
      break;

      // Share
      case (e.shiftKey && $code == $sc.share):
        $('.teaser.hover').find('.coreShareB, .coreShareB').click();
      break;

      //TODO: implement - unsure of purpose
      // Talk
      case (e.shiftKey && $code == $sc.talk):
        //$('.teaser.hover').find('.share').click();
      break;

      case (e.shiftKey && $code == $sc.goTo):
        window.location = $('.teaser.hover').find('.commentC').attr('href')
      break;
    }
  })
})
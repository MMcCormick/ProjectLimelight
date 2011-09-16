$(function() {

  /*
   * LOGIN/REGISTRATION
   */

  $('#login,#register').colorbox({title:"Woops, you need to login to do that!", transition: "none", opacity: .5, inline: true, href: "#auth_box"});

  $('#register').live('click', function() {
    $('.auth-register').click();
  });

  $('#login').live('click', function() {
    $('.auth-login').click();
  });

  // Post-registration Pages
  // Top Nav (1, 2, 3)
  $('#confirm .nav > div').live('click', function() {
    $(this).addClass('on').siblings().removeClass('on');
    $('#confirm .confirmPage').hide();
    $($(this).data('target')).show();
  });
  // Bottom Nav (Next, Last)
  $('#confirm .bottomNav > div').live('click', function() {
    $($(this).data('target')).click();
  });

  /*
   * TOPICS
   */

  // Enabling dragging of topic tags.
  $(".tag.topic").livequery(function() {
    $(this).draggable({
      opacity: 0.7,
      helper: "clone",
      handle: ".handle-small",
      appendTo: "body"
    });
  });

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
  $('.comment .reply_show').live('click', function() {
    var $button = $(this);
    var $reply = $('.comment_reply').clone()
            .find('.comment_reply_name_placeholder').text($button.data('d').name).end()
            .find('.comment_reply_cancel').click(
            function() {
              $reply.remove();
            }).end()
            .appendTo($button.parent().parent())
            .fadeIn(300)
            .find('textarea').focus().end();
    // add the comment parent id to the form action url
    $button.parent().parent().find('form').attr('action', $reply.parent().parent().find('form').attr('action') + '/' + $button.data('d').id);
  });

  // Highlight comments on the same depth level
  $('.comment').live({
    mouseenter: function() {
      $(this).stopTime('comment-hover-stop');
      $(this).stopTime('comment-hover');
      $(this).oneTime(500, "comment-hover", function() {
        $('.comment').removeClass('hover-*');
        $('.d-' + $(this).data('d').d + '.p-' + $(this).data('d').p).addClass('hover-' + $(this).data('d').c);
      })
    },
    mouseleave: function() {
      $(this).stopTime('comment-hover');
      $(this).stopTime('comment-hover-stop');
      $(this).oneTime(500, "comment-hover-stop", function() {
        $('.d-' + $(this).data('d').d + '.p-' + $(this).data('d').p).removeClass('hover-' + $(this).data('d').c);
      })
    }
  })

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
              console.log(data);
              target.qtip('option', {
                'content.text': data,
                'content.ajax': false
              });
            },
            error: function(data) {
              // If self is a ulink, set target to ulink with the given public id, else tlink
              var target = $self.hasClass('ulink') ? $('.ulink[data-pid="'+$self.data('pid')+'"]') : $('.tlink[data-pid="'+$self.data('pid')+'"]');
              console.log(data)
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

  /*
   * FEEDS
   */

  // Hover Class (allows keyboard shortcuts to control hover as well as mouse)
  $('.teaser').live({
    mouseenter: function() {
      if (!$('body').hasClass('shortcut-on')) {
        $('.teaser').removeClass('hover');
        $(this).addClass('hover');
      }
    },
    mouseleave: function() {
      if (!$('body').hasClass('shortcut-on')) {
        $('.teaser').removeClass('hover');
      }
    }
  })
  $('body').mousemove(function() {
    $(this).removeClass('shortcut-on')
  })

  // Resize grid teasers.
  resizeFeedTeasers();
  $(window).resize(function() {
    resizeFeedTeasers();
  });

  // Score tooltip for Grid View
  $('.teaser.grid').livequery(function() {
    $(this).qtip({
      content: {
        text: function(api) {
          return $(this).find('.scoreBox').html();
        }
      },
      position: {
        my: 'left top',
        at: 'top right',
        viewport: $(window),
        adjust: {
          y: 10
        }
      },
      show: {
        delay: 500
      },
      hide: {
        fixed: true,
        delay: 500
      },
      style: {
        classes: 'scoreQ ui-tooltip-shadow',
        tip: {
          corner: true,
          offset: 5
        }
      }
    });
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

  // On keyup
  $(document).keyup(function(e) {

    // If we are focused on a text field or text area
    if ($(e.target).is('input, textarea, select')) {
      return;
    }

    var $code = e.which ? e.which : e.keyCode;
    var $newHover = false;
    console.log($code);

    switch (true) {
      // Nav / Hover Controls
      case ($code == $sc.up || $code == $sc.down || $code == $sc.left || $code == $sc.right):
        $('body').addClass('shortcut-on');

        // If  teaser is hovered
        if ($('.teaser.hover').length > 0) {
          // If first element is hovered and left or up is pressed
          if (($code == $sc.up || $code == $sc.left) && $('.teaser:first').hasClass('hover')) {
            return false;
          }

          // Go to previous
          if ($('.teaser.hover').hasClass('list') && ($code == $sc.up || $code == $sc.left) ||
                  $('.teaser.hover').hasClass('grid') && ($code == $sc.left)) {
            $('.teaser.hover').removeClass('hover').prev().addClass('hover');
          }

          // Go to next
          else if ($('.teaser.hover').hasClass('list') && ($code == $sc.down || $code == $sc.right) ||
                  $('.teaser.hover').hasClass('grid') && ($code == $sc.right)) {
            $('.teaser.hover').removeClass('hover').next().addClass('hover');
          }

          // Jump up a row (for Grid View)
          else if ($('.teaser.hover').hasClass('grid') && ($code == $sc.up)) {
            $('.teaser.hover').removeClass('hover').prevAll().eq(($('#static-data').data('numTeasers') - 1)).addClass('hover');
            if ($('.teaser.hover').length == 0) {
              $newHover = true;
            }
          }

          // Jump down a row (for Grid View)
          else if ($('.teaser.hover').hasClass('grid') && ($code == $sc.down)) {
            $('.teaser.hover').removeClass('hover').nextAll().eq($('#static-data').data('numTeasers') - 1).addClass('hover');
          }
        }

        else {
          $newHover = true;
        }

        // If the app needs to pick a new teaser to hover
        if ($newHover == true) {
          if ($('.teaser:first:onScreen').length > 0) {
            $('.teaser:first').addClass('hover')
          }
          else {
            $('.teaser:onScreen:first').next().addClass('hover');
          }
        }

        // If the new hovered teaser is out of view, adjust viewport according to keystroke
        if (!isScrolledIntoView($('.teaser.hover'), true)) {
          var adjust = ($code == $sc.up || $code == $sc.left) ? '-=500' : '+=500';
          $(window).scrollTo(adjust, 500);
        }

        break;

      // Score Up
      case (e.ctrlKey && $code == $sc.up):
        $('.teaser.hover').find('.thumbs-up-icon').click();
        break;

      // Score Down
      case (e.ctrlKey && $code == $sc.down):
        $('.teaser.hover').find('.thumbs-down-icon').click();
        break;

      // Favorite
      case ($code == $sc.fav):
        $('.teaser.hover').find('.fav').click();
        break;

      // Repost
      case ($code == $sc.repost):
        $('.teaser.hover').find('.repost_B').click();
        break;

      // Share
      case ($code == $sc.repost):
        $('.teaser.hover').find('.share').click();
        break;

      // Talk
      case ($code == $sc.repost):
        $('.teaser.hover').find('.share').click();
        break;

      // Talk
      case ($code == $sc.goTo):
        $('.teaser.hover').find('.commentC').click();
        break;
    }
  })
})
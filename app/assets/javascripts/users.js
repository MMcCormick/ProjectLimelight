$(function() {

  $('#login,#register').colorbox({
    title:false,
    transition: "elastic",
    speed: 200,
    opacity: .90,
    inline: true,
    fixed: true,
    href: "#auth_box"
  });

  if ($('#username_reset_box').length > 0)
  {
    $.colorbox({
      title:false,
      transition: "elastic",
      speed: 100,
      opacity: .95,
      inline: true,
      fixed: true,
      href: "#username_reset_box",
      overlayClose: false,
      escKey: false,
      onLoad: function() {
        $('#cboxClose').remove();
      }
    });
  }

  $('#register').live('click', function() {
    $('#auth-login .switch').click()
  })

  $('#login').live('click', function() {
    $('#auth-register .switch').click()
    $(this).oneTime(200, 'login-focus', function() {
      $('#user_login').focus();
    })
  })

  // Switch between login and register
  $('#auth-login .switch').live('click', function() {
    $(this).closest('.login-reg').hide().siblings().show();
    $('#login,#register').colorbox.resize();
  })
  $('#auth-register .switch').live('click', function() {
    $(this).closest('#auth-register').hide().siblings().show();
    $('#login,#register').colorbox.resize();
  })
  $('.invite .switch').live('click', function() {
    $(this).closest('.invite').hide().siblings().show().find('#auth-register').hide().siblings().show();
    $('#login,#register').colorbox.resize();
  })

  // Show the splash page to new users
  $('#show_splash').livequery(function() {
    $('#register').click();
  })

  // Autocomplete for Core Object Shares
  $('.core_object_share_receivers').livequery(function() {
    $(this).autocomplete($('#static-data').data('d').autocomplete, {
      width: 300,
      multiple: true,
      matchContains: true,
      autoFill: false,
      searchKey: 'username',
      minChars: 2,
      matchSubset: false,
      selectFirst: false,
      mustMatch: false,
      max: 10,
      buckets: [['user', $('#static-data').data('d').userAutoBucket, 'FOLLOWING'], ['user','user','OTHER USERS']],
      extraParams: {"types":['user']},
      allowNew: false,
      dataType: 'json',
      delay: 100,
      formatItem: function(row, i, max) {
        return row.formattedItem;
      },
      formatMatch: function(row, i, max) {
        return row.username;
      },
      formatResult: function(row) {
        return row.username;
      }
      });
      $(this).result(function(event, data, formatted) {
        //TODO: make the qtip not hide when an autocomplete field is clicked (qtip hides on unfocus)
        //$(this).parents('.qtip').qtip('show');
      });
  })

  $('#twitter-c .tweet .include').live('click', function() {
    var parent = $(this).parents('.tweet:first')
    if (parent.hasClass('on'))
    {
      $('#twitter-c .submit span').text(parseInt($('#twitter-c .submit span').text())-1)
    }
    else
    {
      $('#twitter-c .submit span').text(parseInt($('#twitter-c .submit span').text())+1)
    }

    $('#twitter-c .submit').addClass('off')
    parent.toggleClass('on')

    if (parseInt($('#twitter-c .submit span').text()) > 0)
    {
      $('#twitter-c .submit').removeClass('off')
    }
  })

  $('#twitter-c .choose-all').live('click', function() {
    if (parseInt($('#twitter-c .submit span').text()) > 0)
    {
      $('#twitter-c .submit span').text('0');
      $('#twitter-c .submit').addClass('off');
      $('.tweet').removeClass('on');
    }
    else
    {
      $('#twitter-c .submit span').text($('.tweet').length);
      $('#twitter-c .submit').removeClass('off');
      $('.tweet').addClass('on');
    }
  })

  // Submit tweets
  $('#twitter-c .submit').live('click', function() {
    var $self = $(this);

    if ($self.data('processing') || $('.tweet.on').length == 0)
      return false;

    $self.data('processing', true).html('Processing...').addClass('off')
    var $payload = $('.tweet.on input,.tweet.on textarea').serializeArray();

    $.ajax({
      url: $self.data('url'),
      type: 'post',
      dataType: 'json',
      data: $payload,
      success: function(data) {
        appUpdate(data);
      }
    })
  })

  // Topic wall

  // RANDOM FADE IN OF TOPIC WALL
  function randsort(c) {
      var o = new Array();
      for (var i = 0; i < c; i++) {
          var n = Math.floor(Math.random()*c);
          if( jQuery.inArray(n, o) > 0 ) --i;
          else o.push(n);
      }
      return o;
  }
  var e = $('.topic-wall .tile .o') // The elements we're searching
  var c = e.size() // Total number of those elements
  var r = randsort(c) // an array of the element indices in random order
  e.each(function(i) {
    var e = $(this);
    e.fadeTo(0, 0.05);
    setTimeout(function(){
      e.fadeTo(250, 1);
    }, r[i]*20);
  });
  // END RANDOM FADE IN

  $('.topic-wall .tile img').live({
    mouseenter:
      function() {
        var $self = $(this);
        $('.topic-wall').stopTime('show-topic-wall-tile').oneTime(250, 'show-topic-wall-tile', function() {
          $self.data('img_swap', $self.attr('src'));
          $self.attr('src', $self.next('img').attr('src'));
          $self.parent().addClass('hover');
        })
      },
    mouseleave:
      function() {
        var $self = $(this);
        $('.topic-wall').stopTime('show-topic-wall-tile');
        $self.attr('src', $self.data('img_swap'))
        $self.parent().removeClass('hover');
      }

  })
  $('.topic-wall .tile .o[alt]').qtip({
     content: {
        attr: 'alt'
     },
     style: {
       classes: 'ui-tooltip-light ui-tooltip-shadow',
       tip: false
     },
     position: {
       my: 'top center',  // Position my top left...
       at: 'bottom center', // at the bottom right of...
       viewport: $(window),
       adjust: {
          y: -5
       }
     },
     show: {
       delay: 350
     }
  });

})
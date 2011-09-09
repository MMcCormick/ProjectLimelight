(function(window, undefined) {

  // Prepare Variables
  History = window.History,
  rootUrl = History.getRootUrl(),
  $ = window.jQuery,
  $body = $(document.body),
  $application = $('#application'),
  $pageHeader = $('#page_header .wrap'),
  $feedFilters = $('#feed-filters'),
  $pageSidebar1 = $('#page-sb1'),
  $pageSidebar1Content = $('#page-sb1 .wrap'),
  $pageSidebar2 = $('#page-sb2'),
  $pageSidebar2Content = $('#page-sb2 .wrap'),
  $pageSidebar3 = $('#page-sb3'),
  $pageSidebar3Content = $('#page-sb3 .wrap'),
  $pageContent = $('#page_content'),
  $pageContentContent = $('#page_content .wrap'),
  $sidebar = $('#sidebar'),
  $sidebarRight = $('#sidebar-right'),
  $sidebarRightContent = $('#sidebar-right .wrap'),
  $footer = $('#footer'),
  pageClicked = false,// Keeps track of wether a page link has been clicked.
  $currentTarget = null; // The current clicked element.

  // Prepare placeholder function variables
  pageGet = '',
          pageClick = '';

  // Function to capitalize first character of a string
  String.prototype.capitalize = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
  }

  /*
   * Performs various site wide updates.
   * @param object params
   *
   * @return bool Returns true if no conditions stopped progress.
   */
  appUpdate = function(params) {
    // if there's an event, publish it!
    if (params.event) {
      console.log('Event: ' + params.event);
      amplify.publish(params.event, params);
    }

    // Is there a message to show?
    if (params.flash) {
      //alert('Flash: ['++'] '+params.flash.message);
      var theme = params.flash.type == 'error' ? 'red' : 'green';
      createGrowl(false, params.flash.message.capitalize(), params.flash.type.capitalize(), theme);
    }

    if (params.redirect) {
      pageClicked = true;
      pageGet({'url': params.redirect}, pageClick, null);

      return false;
    }

    if (params.reload) {
      document.location = params.reload;
    }

    return true;
  }

  /*
   * Main site-wide action function.
   */
  doAction = function(requestType, params, success, error) {
    console.log('Action:' + params.url);
    var $action = requestType == 'POST' ? 'postAction' : 'getAction';
    amplify.request($action, params, function (data, xhr) {
      // Do we need to login?
      if (xhr.status == 401)
      {
        $('#login').click();
      }
      else
      {
        appUpdate(data);
        if (success) {
          success({'url': params.url}, data);
        }
      }
    })
  };

  /*
   * Show the sitewide loading animation.
   */
  showLoading = function() {
    $body.stopTime('loading').oneTime(400, "loading", function() {
      $body.addClass('loading');
      $('#ajax-loading').fadeIn(150);
    })
  }

  /*
   * Hide the sitewide loading animation.
   */
  hideLoading = function() {
    $body.stopTime("loading");
    $body.removeClass('loading');
    $('#ajax-loading').fadeOut(150);
  }

  // Resize/reset the entire page.
  resetPage = function(rightSidebar) {
    resizeLayout(rightSidebar);
//        resetScrollPane($('.scroll'));
    resizeFeedTeasers();
  }

  /*
   * Use qTip to create 'growl' notifications.
   *
   * @param bool persistent Are the growl notifications persistent or do they fade after time?
   */
  window.createGrowl = function(persistent, content, title, theme) {
    // Use the last visible jGrowl qtip as our positioning target
    var target = $('.qtip.jgrowl:visible:last');

    // Create your jGrowl qTip...
    $(document.body).qtip({
      // Any content config you want here really.... go wild!
      content: {
        text: content,
        //        title: {
        //           text: title,
        //           button: true
        //        }
      },
      position: {
        my: 'bottom left', // Not really important...
        at: 'bottom' + ' left', // If target is window use 'top right' instead of 'bottom right'
        target: target.length ? target : $(document.body), // Use our target declared above
        adjust: { y: (target.length ? -1 * ($('.qtip.jgrowl:visible').height() + 15) : -50), x: (target.length ? 0 : $('#sidebar').width() + 20) } // Add some vertical spacing
      },
      show: {
        event: false, // Don't show it on a regular event
        ready: true, // Show it when ready (rendered)
        effect: function() {
          $(this).stop(0, 1).fadeIn(400);
        }, // Matches the hide effect

        // Custom option for use with the .get()/.set() API, awesome!
        persistent: persistent
      },
      hide: {
        event: false, // Don't hide it on a regular event
        effect: function(api) {
          // Do a regular fadeOut, but add some spice!
          $(this).stop(0, 1).fadeOut(400).queue(function() {
            // Destroy this tooltip after fading out
            api.destroy();

            // Update positions
            updateGrowls();
          })
        }
      },
      style: {
        classes: 'jgrowl ui-tooltip-' + theme + ' ui-tooltip-rounded', // Some nice visual classes
        tip: false // No tips for this one (optional ofcourse)
      },
      events: {
        render: function(event, api) {
          // Trigger the timer (below) on render
          timer.call(api.elements.tooltip, event);
        }
      }
    })
            .removeData('qtip');
  };

  // Make it a window property so we can call it outside via updateGrowls() at any point
  window.updateGrowls = function() {
    // Loop over each jGrowl qTip
    var each = $('.qtip.jgrowl:not(:animated)');
    each.each(function(i) {
      var api = $(this).data('qtip');

      // Set the target option directly to prevent reposition() from being called twice.
      api.options.position.target = !i ? $(document.body) : each.eq(i - 1);
      api.set('position.at', (!i ? 'top' : 'bottom') + ' right');
    });
  };

  // Setup our timer function
  function timer(event) {
    var api = $(this).data('qtip'),
            lifespan = 5000; // 5 second lifespan

    // If persistent is set to true, don't do anything.
    if (api.get('show.persistent') === true) {
      return;
    }

    // Otherwise, start/clear the timer depending on event type
    clearTimeout(api.timer);
    if (event.type !== 'mouseover') {
      api.timer = setTimeout(api.hide, lifespan);
    }
  }

  // Utilise delegate so we don't have to rebind for every qTip!
  $(document).delegate('.qtip.jgrowl', 'mouseover mouseout', timer);

  // END GROWL

  /*
   * FEEDS
   */

  resizeFeedTeasers = function() {
    var $minWidth = 250,
            $maxWidth = 500,
            $feedWidth = $('.object-feed').width() - 1,
            $numTeasers = Math.floor($feedWidth / $minWidth);

    if ($('.teaser.grid').length < $numTeasers) {
      $numTeasers = $('.teaser.grid').length;
    }
    var $newWidth = $feedWidth / $numTeasers;

    $newWidth = $newWidth > $maxWidth ? $maxWidth : $newWidth;

    // Stor
    $('#static-data').data('numTeasers', $numTeasers);
    $('.teaser.grid').outerWidth($newWidth);
  }

  // Resize on page load
  resetPage(true);
  // on window resize
  $(window).resize(function() {
    resetPage(true);
  });

})(window);

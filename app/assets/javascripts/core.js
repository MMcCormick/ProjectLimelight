(function(window, undefined) {

  // Prepare Variables
//  History = window.History,
//  rootUrl = History.getRootUrl(),
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
  $logged = $('#static-data').data('d').myId != 0,
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
   * @param object data
   *
   * @return bool Returns true if no conditions stopped progress.
   */
  appUpdate = function(data) {
    if (!data)
    {
      console.log('no params!')
      return false;
    }

    // if there's an event, publish it!
    if (data.event && data.status == 'ok') {
      console.log("event: "+data.event);
      amplify.publish(data.event, data);
    }

    // Is there a message to show?
    if (data.flash) {
      var theme = data.status == 'error' ? 'red' : 'green';
      createGrowl(false, data.flash.capitalize(), data.status.capitalize(), theme);
    }

    if (data.redirect) {
      window.location = data.redirect

      return false;
    }

    if (data.reload) {
      document.location = data.reload;
    }

    return true;
  }

  /*
   * Main site-wide action functions.
   */
  doAction = function(url, requestType, params, success, error) {
    $.ajax({
      url: url,
      type: requestType,
      dataType: 'json',
      data: params,
      success: function(data) {
        $currentTarget.data('processing', false);
        appUpdate(data);
        if (success) {
          success(params, data);
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        var data = JSON.parse(jqXHR.responseText)
        appUpdate(data);

        if (jqXHR.status == 401 && $('#login').length > 0)
        {
          $('#login').click()
          createGrowl(false, 'You need to be logged in to do that.', '', 'red');
        }
        else if (jqXHR.status == 500)
        {
          createGrowl(false, 'Woops! There was an error. We\'ve been notified and will look into it ASAP.', '', 'red');
        }

        if (error) {
          error(params, data);
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

  // Resize on page load
  resetPage(true);
  // on window resize
  $(window).resize(function() {
    resetPage(true);
  });

})(window);

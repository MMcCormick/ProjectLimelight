(function(window, undefined) {

  // Prepare Variables
//  History = window.History,
//  rootUrl = History.getRootUrl(),
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
        if ($currentTarget)
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
          $('#register').click()
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
   * Use gritter to create 'growl' notifications.
   *
   * @param bool persistent Are the growl notifications persistent or do they fade after time?
   */
  window.createGrowl = function(persistent, content, title, theme) {
    $.gritter.add({
    	// (string | mandatory) the heading of the notification
    	title: title,
    	// (string | mandatory) the text inside the notification
    	text: content,
    	// (string | optional) the image to display on the left
    	image: false,
    	// (bool | optional) if you want it to fade out on its own or just sit there
    	sticky: false,
    	// (int | optional) the time you want it to be alive for before fading out (milliseconds)
    	time: 8000,
    	// (string | optional) the class name you want to apply directly to the notification for custom styling
    	class_name: 'gritter-'+theme,
      // (function | optional) function called before it opens
    	before_open: function(){
    	},
    	// (function | optional) function called after it opens
    	after_open: function(e){
    	},
    	// (function | optional) function called before it closes
    	before_close: function(e, manual_close){
        // the manual_close param determined if they closed it by clicking the "x"
    	},
    	// (function | optional) function called after it closes
    	after_close: function(){
    	}
    });
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

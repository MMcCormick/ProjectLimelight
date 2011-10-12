/*
 * This script handles page loads/transitions.
 * It uses history.js and amplify.js functionality.
 */
(function(window, undefined) {

  // Check to see if History.js is enabled for our Browser
//  if (!History.enabled) {
//    return false;
//  }

  // Ajaxify our Internal Links
//  $application.find('a[href^="/"].p,a[href^="' + rootUrl + '"].p').live('click', function(event) {
//    // Continue as normal for cmd clicks etc
//    if (event.which == 2 || event.metaKey) {
//      return true;
//    }
//
//    pageClicked = true;
//    $currentTarget = $(this);
//    pageGet({'url': $(this).attr('href')}, pageClick);
//    event.preventDefault();
//
//    return false;
//  });

  /*
   * Hook into State Changes.
   * If this state change is not due to a click, get the new page.
   */
  $(window).bind('statechange', function() {
    if (pageClicked)
      return false;

    pageGet({'url': History.getState().url}, null, null);
  });

  /*
   * Gets a new page.
   */
  pageGet = function(params, success, error) {

    // Set Loading
    showLoading();

    console.log('Page change:' + params.url);

    // Add the format parameter (xml) with special case for homepage
    var $path = params.url.split('.php');
    $path = $path[$path.length - 1];
    $delim = !$path ? '/' : '';

    var url = (!$path || $path == '/' || params.url[params.url.length - 1] == '/' ? params.url + $delim + 'home.ajax' : params.url + '.ajax');

    amplify.request("pageGet", { 'url': url }, function (data) {
      if ($.isEmptyObject(data)) {
        hideLoading();
        return false;
      }

      if (pageUpdate(data) && success) {
        success({'url': params.url}, data);
      }
    })

  };

  /*
   * Updates page content areas in response to a page load.
   *
   * @param object params
   * @attribute html pageHeader
   * @attribute html pageContent
   * @attribute html sidebar
   * @attribute string title
   */
  var pageUpdate = function(params) {
    hideLoading();

    if (appUpdate(params) && params.pageRefresh) {
      $pageHeader.html(params.pageHeader ? params.pageHeader : '');
      $feedFilters.html(params.feedFilters ? params.feedFilters : '');
      $sidebar.html(params.sidebar);
      $footer.html(params.footer);

      // Content areas that have scroll panes
      $pageSidebar1Content.html(params.pageSidebar1 ? params.pageSidebar1 : '');
      $pageSidebar2Content.html(params.pageSidebar2 ? params.pageSidebar2 : '');
      $pageSidebar3Content.html(params.pageSidebar3 ? params.pageSidebar3 : '');
      $pageContentContent.html(params.pageContent);

      if (params.sidebarRight) {
        $sidebarRightContent.html(params.sidebarRight);
        resetPage(true);
      }
      else {
        $sidebarRightContent.empty();
        $sidebarRight.width(0);
        resetPage(false);
      }
    }
    // Do we need to refresh the page?
    else if (!params.pageRefresh) {
      return false;
    }

    return true;
  }

  /*
   * Pushes a new page state, and resets the pageClicked variable.
   */
  var pageClick = function(params, data) {
    History.pushState(null, data.title, params.url);
    pageClicked = false;
  }

})(window); // end closure
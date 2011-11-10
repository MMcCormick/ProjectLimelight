/*
 * Fixes for development environment
 */

/*
 * Control the main content resizing
 */
var resizeLayout = function(rightSidebarAdjust) {
  var pageHeader = $('#page_header');
  var sidebar = $('#sidebar');
  var rightSidebar = $('#sidebar-right .sbrC');
  var footer = $('#footer').height();
  var h = $(window).height() - footer;

  sidebar.css('height', h - 7 - parseInt(sidebar.css('left').replace("px", "")) * 2);

  var w = $('body').width() - 4
          - (sidebar.width() + parseInt(sidebar.css('left').replace("px", "")));


  if (rightSidebar.length > 0) {
    rightSidebar.css('height', h - 2 - parseInt(rightSidebar.css('margin-top').replace("px", "")) * 2);

    if (rightSidebarAdjust) {
      w -= 10 + rightSidebar.width() + parseInt(rightSidebar.css('margin-right').replace("px", ""));
    }
  }

  pageHeader.css({width: w + 2});

  $('#page').css({'padding-top': pageHeader.height() + 10, width: w + 2});

  $('#page-sb1 .wrap, #page-sb2 .wrap, #page-sb3 .wrap').css('height', h - pageHeader.height());
};

// Check if something is visible on the screen
function isScrolledIntoView(elem, bufferOn, checkAll, entireElem) {
  var docViewTop = $(window).scrollTop();
  var docViewBottom = docViewTop + $(window).height();

  var elemTop = $(elem).offset() ? $(elem).offset().top : 0;
  var elemBottom = elemTop + $(elem).height();

  var pageHeader = $('#page_header.floating').length > 0 && bufferOn ? $('#page_header.floating').height() - 15 : 0;
  var footer = bufferOn ? $('#footer').height() : 0;

  var inView;
  if (entireElem) {
  inView = (elemTop <= docViewBottom - footer) && (elemBottom >= docViewTop + pageHeader)
    && (elemBottom <= docViewBottom - footer) && (elemTop >= docViewTop + pageHeader)
  }
  else {
  inView = (elemTop <= docViewBottom - footer) && (elemBottom >= docViewTop + pageHeader)
  }

  if (checkAll)
  {
    viewable = viewable && (elemBottom <= docViewBottom - footer) && (elemTop >= docViewTop + pageHeader)
  }

  return inView;
}

function handleScroll() {
  if (isScrolledIntoView($('#header'), false, false)) {
    $('#sidebar,#page_header,#sidebar-right,#ajax-loading').removeClass('floating');
    $('#page').css('margin-right', 0);
  }
  else {
    $('#sidebar,#page_header,#sidebar-right,#ajax-loading').addClass('floating');
    if ($('#sidebar-right .sbrC').length > 0) {
      $('#page').css('margin-right', 2 + $('#sidebar-right .sbrC').width() + parseInt($('#sidebar-right .sbrC').css('margin-right').replace("px", "")));
    }
  }
}

handleScroll();
$(window).scroll(function() {
  handleScroll();
})
/*
 * Fixes for development environment
 */

/*
 * Control the main content resizing
 */
var resizeLayout = function(rightSidebarAdjust) {
  var header = $('#header');
  var footer = $('#footer');
  var h = $(window).height() - header.height() - footer.height() - 50;

  $('#colmask,#colmid,#page,#page_content,#page_inside').css('min-height', h);
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

// Arrange Column format in feeds
function rearrange_feed_columns()
{
  var $min_spacing = 15;

  if ($('.teaser.column').length == 0)
  {
    return;
  }

  $('#core-feed').css('width', 'auto');

  // Calculate the # of columns
  var feed_min_column = 99999999;
  var teaser_width = $('.teaser.column').width();
  var feed_columns_num = Math.floor(($('#page_inside').width() - 5) / (teaser_width + $min_spacing));
  var feed_columns_spacing = Math.floor(($('#page_inside').width() - 5) - (teaser_width * feed_columns_num)) / (feed_columns_num+1);

  if ($('#core-feed').data('column-count') == feed_columns_num && $('#core-feed > .teaser.column').length == 0)
  {
    $('.feed-vertical-column').css('margin-left', feed_columns_spacing);
    return;
  }

  var target_teasers = $('.teaser.column');

  if ($('#core-feed').data('column-count') != feed_columns_num)
  {
    $('#core-feed').data('column-count', feed_columns_num);

    // Set the old columns
    $('.feed-vertical-column').addClass('old');

    // Build and append the new columns
    var feed_columns = [];
    for(var i=0; i<feed_columns_num; i++) {
      feed_columns.push({column: $('<div/>').addClass('feed-vertical-column'), total_height: 0});
      $('#core-feed').append(feed_columns[i].column);
    }
  }
  else
  {
    var feed_columns = [];
    $('.feed-vertical-column').each(function(i,val) {
      feed_columns.push({column: $(val), total_height: $(val).outerHeight()});
    })

    target_teasers = $('#core-feed > .teaser.column');
  }

  $('.feed-vertical-column').css('margin-left', feed_columns_spacing);

  // Sort the teasers into columns
  target_teasers.each(function(i,val) {
    var chosen_column = 0;
    for(var i=0; i<feed_columns.length; i++) {
      if (feed_columns[i].total_height <= feed_min_column)
      {
        chosen_column = i;
        feed_columns[i].total_height += $(val).outerHeight();
        break;
      }
    }

    feed_min_column = 9999999;
    for(var i=0; i<feed_columns.length; i++) {

      if (feed_columns[i].total_height <= feed_min_column)
      {
        feed_min_column = feed_columns[i].total_height;
      }
    }

    feed_columns[chosen_column].column.append($(val));
    $(val).fadeIn(750);
  })

  // Remove the old columns
  $('.feed-vertical-column.old').remove();
  $('#core-feed').css('width', $('#core-feed').width());
}

var didScroll = false;
$(window).scroll(function() {
  didScroll = true;
})

function handleScroll() {
  if (didScroll)
  {
    if (isScrolledIntoView($('#header'), false, false)) {
      $('.sidebar .top, #page_header').removeClass('floating').css('left', '0');
      $('.sidebar, #page_inside').css('padding-top', '0px');
    }
    else {
      $('#page_inside').css('padding-top', $('#page_header').outerHeight());
      $('.sidebar.left').css('padding-top', $('.sidebar.left .top').outerHeight());
      $('.sidebar.right').css('padding-top', $('.sidebar.right .top').outerHeight());
      $('#page_header').css('width', $('#page_inside').width());
      $('.sidebar .top, #page_header').each(function() {
        $(this).css('left', $(this).offset().left+'px');
        $(this).addClass('floating');
      });
    }
    didScroll = false;
  }
}

handleScroll();
setInterval(handleScroll, 250);

// Hide duplicate personal/private talks on feed teasers
$('.response').livequery(function() {
  $(this).each(function(i,val) {
    if ($('.response[data-id="'+$(val).data('id')+'"]').length > 1)
    {
      $(this).parents('.teaser:first').find('.public').hide();
    }
  })
})
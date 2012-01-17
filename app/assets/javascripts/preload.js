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
  var $spacing = 18;

  if ($('.teaser.column').length == 0)
  {
    $('#core-feed').css('height', 'auto');
    return;
  }

  var feed_min_column = 99999999;
  var teaser_width = $('.teaser.column').width();
  var feed_columns_num = Math.floor(($('#page_inside').width() - 5) / (teaser_width + $spacing));
  var feed_columns = []
  for(var i=0; i<feed_columns_num; i++) {
    feed_columns.push({total_height: 0, teasers:[]})
  }

  $('.teaser.column').each(function(i,val) {
    var chosen_column = 0;
    for(var i=0; i<feed_columns.length; i++) {
      if (feed_columns[i].total_height < feed_min_column)
      {
        chosen_column = i;
        feed_min_column = feed_columns[i].total_height;
      }
    }

    feed_columns[chosen_column].total_height += $(val).height();
    feed_columns[chosen_column].teasers.push ($(val));
    feed_min_column = 999999999;
  })

  var max_column_height = 0;

  for(var i=0; i<feed_columns.length; i++) {
    var column_height = 10;
    for(var i2=0; i2<feed_columns[i].teasers.length; i2++) {
      $(feed_columns[i].teasers[i2]).css({
        'position': 'absolute',
        'top': column_height,
        'left': teaser_width*i+$spacing*(i)+10
      });
      $(feed_columns[i].teasers[i2]).attr('data-column', i).data('column', i);
      $(feed_columns[i].teasers[i2]).show();
      column_height += $(feed_columns[i].teasers[i2]).height() + $spacing*2.35;
    }
    if (column_height > max_column_height) {
      max_column_height = column_height
    }
  }
  $('#core-feed').css('height', max_column_height).data('numcols', feed_columns_num)
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
      $('#page_header').css('width', $('#page_header').width());
      $('.sidebar .top, #page_header').each(function() {
        $(this).css('left', $(this).offset().left+'px')
        $(this).addClass('floating')
      });
    }
    didScroll = false;
  }
}

handleScroll();
setInterval(handleScroll, 250);

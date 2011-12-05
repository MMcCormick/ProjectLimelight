/*
 * Fixes for development environment
 */

/*
 * Control the main content resizing
 */
var resizeLayout = function(rightSidebarAdjust) {
  var pageHeader = $('#page_header');
  var sidebar = $('#sidebar');
  var footer = $('#footer');
  var h = $(window).height() - footer.height();

  sidebar.css('height', h - 36);
  if (pageHeader.hasClass('floating'))
  {
    pageHeader.css({width: parseInt($('#page_content').width())+parseInt($('#page_content').css('padding-right').replace("px", ""))-14});
  }
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
  if ($('.teaser.column').length == 0)
  {
    $('#core-feed').css('height', 'auto');
    return;
  }

  var feed_min_column = 99999999;
  var teaser_width = $('.teaser.column').width();
  var feed_columns_num = Math.floor(($('#page_content').width() - 5) / (teaser_width + 10));
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
    var column_height = 0;
    for(var i2=0; i2<feed_columns[i].teasers.length; i2++) {
      $(feed_columns[i].teasers[i2]).css({
        'position': 'absolute',
        'top': column_height,
        'left': teaser_width*i+10*(i+1)
      });
      $(feed_columns[i].teasers[i2]).attr('data-column', i).data('column', i);
      $(feed_columns[i].teasers[i2]).show();
      column_height += $(feed_columns[i].teasers[i2]).height() + 10;
    }
    if (column_height > max_column_height) {
      max_column_height = column_height
    }
  }
  $('#core-feed').css('height', max_column_height).data('numcols', feed_columns_num)
}

function handleScroll() {
  if (isScrolledIntoView($('#header'), false, false)) {
    $('#sidebar,#page_header,#ajax-loading').removeClass('floating');
    $('#sidebar').css('left', 0);
    $('#page_header').css('width', 'auto');
    $('#page_content').css('margin-top', 10);
  }
  else {
    $('#page_header').css('width', $('#page_header').width());
    $('#sidebar,#page_header,#ajax-loading').addClass('floating');
    $('#sidebar').css('left', $('#page').offset().left);
    $('#page_content').css('margin-top', $('#page_header').height()+10);
  }
}

handleScroll();
$(window).scroll(function() {
  handleScroll();
})
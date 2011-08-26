/*
 * Fixes for development environment
 */

/*
 * Control the main content resizing
 */
var resizeLayout = function(rightSidebarAdjust)
{
    var pageHeader = $('#page_header');
    var sidebar = $('#sidebar');
    var rightSidebar = $('#sidebar-right .sbrC');
    var footer = $(window).height() - $('#footer').offset().top;
    var h = $(window).height() - footer;

    sidebar.css('height', h-2-parseInt(sidebar.css('margin-top').replace("px", ""))*2);

    var w = $(window).width() - 4
            - (sidebar.width() + parseInt(sidebar.css('margin-left').replace("px", "")));


    if (rightSidebar.length > 0)
    {
        rightSidebar.css('height', h-2-parseInt(rightSidebar.css('margin-top').replace("px", ""))*2);

        if (rightSidebarAdjust)
        {
            w -= 20 + rightSidebar.width() + parseInt(rightSidebar.css('margin-right').replace("px", ""));
        }

        w += 4;
    }

    pageHeader.css({width: w+2});

    $('#page').css({'padding-top': pageHeader.height()+10, width: w+2});

    $('#page-sb1 .wrap, #page-sb2 .wrap, #page-sb3 .wrap').css('height', h-pageHeader.height());
};

// Check if something is visible on the screen
function isScrolledIntoView(elem, bufferOn)
{
    var docViewTop = $(window).scrollTop();
//    var docViewBottom = docViewTop + $(window).height();

    var elemTop = $(elem).offset().top;
    var elemBottom = elemTop + $(elem).height();

    var pageHeader = $('#page_header.floating').length > 0 && bufferOn ? $('#page_header.floating').height()-15 : 0;
    var footer = bufferOn ? $('#footer').height() : 0;

    return ((elemTop-pageHeader <= docViewTop) && (elemBottom+footer >= docViewTop));
}

function handleScroll()
{
    if (isScrolledIntoView($('#header'), false))
    {
        $('#sidebar,#page_header,#sidebar-right,#ajax-loading').removeClass('floating');
        $('#page').css('margin-right', 0);
    }
    else
    {
        $('#sidebar,#page_header,#sidebar-right,#ajax-loading').addClass('floating');
        if ($('#sidebar-right .sbrC').length > 0)
        {
            $('#page').css('margin-right', 2 + $('#sidebar-right .sbrC').width() + parseInt($('#sidebar-right .sbrC').css('margin-right').replace("px", "")));
        }
    }
}

handleScroll();
$(window).scroll(function() {
    handleScroll();
})
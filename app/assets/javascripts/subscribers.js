// Wait for Document
$(function() {

  var actionCommon = function(target, data) {
    if (data.newText) {
      target.html(data.newText);
    }

    if (data.newUrl) {
      target.attr('href', data.newUrl);
    }
  }

  var deleteCommon = function (data) {
    $('.o-' + data.objectId).remove();
  }

  var editCommon = function (data, target) {
    $(target).data('original', $(target).html()).html(data);
  }

  // Listens to votes being registered.
  amplify.subscribe("votes_create votes_destroy", function(data) {
    // This function makes the vote buttons turn on and off appropriately
    var $target = $('.v_'+data.id).parents('.scoreC:first')
    if (data.a > 0)
    {
      $target.find('.up').removeClass('voteB').addClass('unvoteB')
      $target.find('.down').removeClass('unvoteB').addClass('voteB')
    }
    else if (data.a == 0)
    {
      $target.find('.up, .down').removeClass('unvoteB').addClass('voteB')
    }
    else
    {
      $target.find('.up').removeClass('unvoteB').addClass('voteB')
      $target.find('.down').removeClass('voteB').addClass('unvoteB')
    }
  });

  // Listens for favorite toggles.
  amplify.subscribe("favorites_create favorites_destroy", function(data) {
    $('.p_'+data.id).text(parseInt(data.popularity));
  });

  // Listens for follow button events.
  amplify.subscribe("follow_toggle", function(data) {
    actionCommon($('.fol_' + data.objectId), data);
  });

  // Listens for follow button events.
  amplify.subscribe("reposts_create reposts_destroy", function(data) {
    $('.p_'+data.id).text(parseInt(data.popularity));
  });

  /*
   * GENERAL
   */
  amplify.subscribe("application_sidebar", function(data) {
    $('#page,#page_header').toggleClass('minimized-sidebar');
    $('#sidebar .full,#sidebar .minimized').toggle();
    resizeLayout();
    rearrange_feed_columns();
  })

  /*
   * LISTS
   */

  /*
   * HELP
   */

  amplify.subscribe('help_tutorial_off', function (data) {
    $('#hp:visible,.hf:visible').hide('scale', {}, 200)
    if ($('#top-contribute:visible').length == 1)
      $('#contribute').click()
  })

  /*
   * TOPICS
   */

  amplify.subscribe("topics_edit", function (data) {
    $('#topic-edit').hide()
    $('#topic-panel .content').slideUp(300)
    $('#topic-edit').html(data.content)
    $('#topic-edit').slideDown(300)
  })

  /*
   * TALK
   */

  /*
   * FEEDS
   */

  // Clears forms, adds responses to response area
  amplify.subscribe("talks_create news_create pictures_create videos_create", function (data) {
    if(data.status == "ok") {
      if (data.response) {
        $('#add_response').click();
        $('#responses').prepend(data.teaser);
        contribute = $('#response-contribute')
      }
      else {
        $('#contribute').click();
        contribute = $('#top-contribute');

        $('#my-contributions').qtip({
          content: {
            text: 'Your '+data.type+' was successfully created.<br/>'+
                  '<a href="'+data.path+'">Click here to view it</a>'+
                  '<br/> or see all in "Contributions"'
          },
          style: {classes: 'object-created-tip ui-tooltip-shadow ui-tooltip-light ui-tooltip-green', tip: true},
          position: {
            my: 'left top',
            at: 'right middle',
            viewport: $(window)
          },
          hide: {delay: 300, inactive: 5000},
          events: {
            hide: function(event, api) {
              $('#my-contributions').qtip('destroy');
            }
           }
        });
        $('#my-contributions').qtip('show')
      }
      // Clear forms on appropriate window
      contribute.find('.lClear input, .lClear textarea, .iClear input').val("").focus().blur();
      contribute.find('.image-preview .images img').remove();
    }
  });

  // When a new page of feed items is loaded
  amplify.subscribe("loaded_feed_page", function (data) {
    $('#load-more').remove()
    if (data.full_reload)
    {
      $('#core-feed').replaceWith(data.content);
    }
    else
    {
      var content = $(data.content)[0]
      $('#core-feed').append($(content).html())
      $('#core-feed').after($(data.content)[2]);
    }
    rearrange_feed_columns();
  });

  /*
   * COMMENTS
   */

  amplify.subscribe("comments_create", function (data) {
    if (data.parent_id) {
      $('#comment_' + data.parent_id).after(data.comment);
    }
    else {
      $('.c_'+data.talk_id).show().prepend(data.comment);
    }
    $('.comment_form:visible').remove();
  })

  /*
   * USER
   */

  /*
   * SHARING
   */

  amplify.subscribe("core_object_shares_create", function (data) {
    $('.qtip').qtip('hide')
    $currentTarget.clearForm();
  })

});
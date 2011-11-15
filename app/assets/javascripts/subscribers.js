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

  // Loads a newly created object into the beginning of the feed
  // TODO: clear forms
  amplify.subscribe("talks_create", function (data) {
    if (data.response) {
      $('#responses').prepend(data.teaser);
      $('#add_response').click();
    }
    else {
      $('#core-feed').prepend(data.teaser);
      $('#contribute').click();
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
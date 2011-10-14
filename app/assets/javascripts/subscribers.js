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
    var $target = $(data.target).parents('.scoreC:first')
    if (data.a > 0)
    {
      console.log("a > 0")
      $target.find('.up').removeClass('voteB').addClass('unvoteB')
      $target.find('.down').removeClass('unvoteB').addClass('voteB')
    }
    else if (data.a == 0)
    {
      console.log("a == 0")
      $target.find('.up, .down').removeClass('unvoteB').addClass('voteB')
    }
    else
    {
      console.log("a < 0")
      $target.find('.up').removeClass('unvoteB').addClass('voteB')
      $target.find('.down').removeClass('voteB').addClass('unvoteB')
    }
  });

  // Listens for favorite toggles.
  amplify.subscribe("favorite_toggle", function(data) {
    // Update the objects scores
    $('.fav_' + data.objectId).toggleClass('on');
  });

  // Listens for follow button events.
  amplify.subscribe("follow_toggle", function(data) {
    actionCommon($('.fol_' + data.objectId), data);
  });

  // Listens for follow button events.
  amplify.subscribe("repost_toggle", function(data) {
    actionCommon($('.rp_' + data.objectId), data);
  });

  // Listens for when the contribute button is clicked
  amplify.subscribe("contribute_form", function(data) {
    $.colorbox({title:"Give us some shit!", transition: "none", opacity: .5, html: data.form, scrolling: false });
  });


  /*
   * LISTS
   */

  amplify.subscribe("list_created", function(data) {
    $sidebar.find('ul.list').append('<li>' + data.object + '</li>');
  });

  amplify.subscribe("list_delete", function(data) {
    deleteCommon(data);
  });

  /*
   * TOPICS
   */

  amplify.subscribe("topic_edit_show", function (data) {
    $('#topic-edit').hide()
    $('#topic-panel .content').slideUp(300)
    $('#topic-edit').html(data.content)
    $('#topic-edit').slideDown(300)
  })

  // Topic types
  amplify.subscribe("edit_topic_type", function (data) {
    $currentTarget.clearForm();
    $('.qtip').qtip('hide')
  })

  /*
   * TALK
   */

  amplify.subscribe("talk_delete", function(data) {
    deleteCommon(data);
  });

  /*
   * FEEDS
   */

  // When a new page of feed items is loaded
  amplify.subscribe("loaded_feed_page", function (data) {
    $('#load-more').replaceWith(data.content)
  });

  amplify.subscribe("feed_filter_toggle", function (data) {
  });

  amplify.subscribe("feed_filter_change", function (data) {
  });

  /*
   * COMMENTS
   */

  amplify.subscribe("comment_created", function (data) {
    if (data.parentId) {
      $('#' + data.parentId).after(data.comment);
    }
    else {
      $('.comments').prepend(data.comment);
    }
    $('.comment .comment_reply').remove();
    $('.comments').prev('h3').find('span').text(parseInt($('.comments').prev('h3').find('span').text()) + 1);
  })

  /*
   * USER
   */

  amplify.subscribe("user_confirmed", function (data) {
    $('#login,#register').colorbox.close();
  })

  amplify.subscribe("register_error", function (data) {
    $('#login,#register').colorbox.resize();
  })

  /*
   * SHARING
   */

  amplify.subscribe("core_object_share_finished", function (data) {
    $('.qtip').qtip('hide')
    $currentTarget.clearForm();
  })

});
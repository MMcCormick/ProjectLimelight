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
  amplify.subscribe("vote_toggle", function(data) {
    // Turn the scorebox voted button on
    var $target = $currentTarget.hasClass('u') ? '.u' : '.d';
    $('#mouse-score, .sb-' + $currentTarget.parent().data('id')).find($target).toggleClass('on').siblings().removeClass('on');

    // Update the objects scores
    $('.s-' + data.objectId).text(data.objectNewScore);

    // Update the user score
    $('.s-' + data.affectedUserId).text(data.affectedUserNewScore);
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
    editCommon(data.form, "#sidebar-right .wrap");

    resetPage(true);
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
    $currentTarget.find('.core_object_share_receivers').val('');
  })

});
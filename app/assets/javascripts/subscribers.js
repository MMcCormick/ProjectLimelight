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

  // Listens for follow button on topic cards in the topic finder.
  amplify.subscribe("follows_create sentiments_create", function(data) {
    var topicCard = $currentTarget ? $currentTarget.parents('.topic-card:first') : null;
    if (topicCard && topicCard.length > 0)
    {
      used_ids = []
      $('.topic-card').each(function(i, val) {
        used_ids.push($(val).data('id'));
      })
      $.ajax({
        url: topicCard.parents('.topic-cards').data('url'),
        type: 'get',
        dataType: 'json',
        data: { u: used_ids },
        success: function(data) {
          if (data.card != '')
          {
            console.log(data.card);
            console.log($(data.card));
            topicCard.fadeTo(150, .01, function() {
              topicCard.replaceWith($(data.card)).fadeTo(150, .75);
            })
          }
          else
          {
            topicCard.remove();
          }
        }
      })
    }
  });

  // Listens for repost button events.
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
  });

  /*
   * TOPICS
   */

  amplify.subscribe("topics_create", function (data) {
    if (data.status == "ok") {
      $('#created-topics').append(data.tlink);
      $('#new-topic .field').find('textarea, input').val('');
    }
  });

  amplify.subscribe("topics_edit", function (data) {
    $('#topic-edit').hide()
    $('#topic-panel .content').slideUp(300)
    $('#topic-edit').html(data.content)
    $('#topic-edit').slideDown(300)
  });

  // topic pull from box that shows the topics a topic is pulling from
  amplify.subscribe('topics_pull_from', function (data) {
    $.colorbox({
      title:false,
      transition: "elastic",
      speed: 100,
      opacity: '.95',
      width: 500,
      height: 400,
      fixed: true,
      html: data.html
    })
  })


  // When a new page in an alt-list is loaded
  amplify.subscribe("loaded_alt_list", function (data) {
    $('#load-more').remove()
    var content = $(data.content)
    $('.alt-list').append(content)
  });

  /*
   * TOPIC CONNECTIONS
   */

  amplify.subscribe("topic_con_sugs_create", function (data) {
    $('#sug-list').prepend(data.teaser)
  });

  /*
   * TALK
   */

  /*
   * FEEDS
   */

  // Clears forms, adds responses to response area
  amplify.subscribe("talks_create links_create pictures_create videos_create", function (data) {
    if(data.status == "ok") {
      if (data.response) {
        $('#add_response').click();
        $('#responses').prepend(data.teaser);
        contribute = $('#response-contribute')
      }
      else {
        $('#contribute').click();
        contribute = $('#top-contribute');

        $('.sidebar.left .contributions').qtip({
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
              $('.sidebar.left .contributions').qtip('destroy');
            }
           }
        });
        $('.sidebar.left .contributions').qtip('show')
      }
      // Clear forms on appropriate window
      contribute.find('.option.on .cancel').click();
      contribute.find('.lClear input, .lClear textarea, .iClear input').val("").focus().blur();
      contribute.find('.image-preview .images img').remove();
      contribute.find('.under').html('');
      contribute.find('.mentions').html('');
      contribute.find('.mention-ooc .hidden_data').val('{"existing":[],"new":[]}');
    }
  });

  // Removes a deleted core object
  amplify.subscribe("talks_disable links_disable pictures_disable videos_disable", function (data) {
    if(data.status == "ok") {
      $currentTarget.parents('.teaser:first').remove();
    }
    rearrange_feed_columns();

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

    $('#core-feed .overlay').stopTime('show_overlay', function() {
      $(this).hide();
    })

    if ($('#core-feed').hasClass('list'))
    {
      $('body').addClass('narrow')
    }
    else
    {
      $('body').removeClass('narrow')
    }

    $('#page_header').css('width', 'auto');

    resizeLayout();
    rearrange_feed_columns();
  });

  /*
   * COMMENTS
   */

  amplify.subscribe("comments_create", function (data) {
    if (data.status == "ok")
    {
      if (data.parent_id) {
        $('#comment_' + data.parent_id).after(data.comment);
      }
      else {
        $('.c_'+data.talk_id).show().find('.comments').prepend(data.comment);
      }
      $('.comment_reply:visible').remove();
    }
  })

  amplify.subscribe("comments_destroy", function (data) {
    if (data.status == "ok")
    {
      $('#comment_' + data.id).replaceWith(data.comment)
    }
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

  /*
   * AUTHORIZATION
   */
  amplify.subscribe("invite_codes_check", function (data) {
    console.log(data);
    if (data.status == "ok") {
      $('#auth_box').find('.invite').hide();
      $('#auth_box').find('.login-reg').show().find("#auth-login").hide().siblings().show()
      $('#auth_box').find('#user_invite_code_id').val(data.invite_code_id)
    }
  })

});
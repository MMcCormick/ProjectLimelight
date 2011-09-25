$(function() {

  /*
   * LOGIN/REGISTRATION
   */

  $('#login,#register').colorbox({title:"Woops, you need to login to do that!", transition: "none", opacity: .5, inline: true, href: "#auth_box"});

  $('#register').live('click', function() {
    $('.auth-register').click();
  })

  $('#login').live('click', function() {
    $('.auth-login').click();
  })

  // Post-registration Pages
  // Top Nav (1, 2, 3)
  $('#confirm .nav > div').live('click', function() {
    $(this).addClass('on').siblings().removeClass('on');
    $('#confirm .confirmPage').hide();
    $($(this).data('target')).show();
  })
  // Bottom Nav (Next, Last)
  $('#confirm .bottomNav > div').live('click', function() {
    $($(this).data('target')).click();
  })

  /*
   * USERS
   */

  // Toggle login and register in the authentication box
  $('#auth_box .form-toggle').live('click', function() {
    $('#auth-login, #auth-register').hide();
    $($(this).data('target')).show();
    $(this).addClass('on').siblings('.form-toggle').removeClass('on');
    $('#login,#register').colorbox.resize();
  })

  // Toggle the left sidebar
  $('.toggleSidebar').live('click', function() {
    $('#page,#page_header').toggleClass('minimized-sidebar');
    $('#sidebar .full,#sidebar .minimized').toggle();
    resizeLayout();
    resizeFeedTeasers();
  });

  // Autocomplete for Core Object Shares
  $('.core_object_share_receivers').livequery(function() {
    $(this).autocomplete($('#static-data').data('d').userAutoUrl, {
      minChars: 1,
      width: 175,
      matchContains: true,
      autoFill: false,
      searchKey: 'username',
      formatItem: function(row, i, max) {
        return row.formattedItem;
      },
      formatMatch: function(row, i, max) {
        return row.name;
      },
      formatResult: function(row) {
        return row.username;
      }
      });
      $(this).result(function(event, data, formatted) {
        //TODO: make the qtip not hide when an autocomplete field is clicked (qtip hides on unfocus)
        //$(this).parents('.qtip').qtip('show');
      });
  })

})
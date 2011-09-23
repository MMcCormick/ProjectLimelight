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

})
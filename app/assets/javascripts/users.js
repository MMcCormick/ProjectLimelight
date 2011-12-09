$(function() {

  $('#login,#register').colorbox({
    title:false,
    transition: "elastic",
    speed: 200,
    opacity: .90,
    inline: true,
    fixed: true,
    href: "#auth_box"
  });

  if ($('#username_reset_box').length > 0)
  {
    $.colorbox({
      title:false,
      transition: "elastic",
      speed: 100,
      opacity: .95,
      inline: true,
      fixed: true,
      href: "#username_reset_box",
      overlayClose: false,
      escKey: false,
      onLoad: function() {
        $('#cboxClose').remove();
      }
    });
  }

  $('#register').live('click', function() {
    $('#auth-login .switch').click()
  })

  $('#login').live('click', function() {
    $('#auth-register .switch').click()
    $(this).oneTime(200, 'login-focus', function() {
      $('#user_login').focus();
    })
  })

  // Toggle login and register in the authentication box
  $('#auth_box .switch').live('click', function() {
    $(this).parent().hide().siblings().show();
    $('#login,#register').colorbox.resize();
  })

  // Show the splash page to new users
  $('#show_splash').livequery(function() {
    $('#register').click();
  })

  // Autocomplete for Core Object Shares
  $('.core_object_share_receivers').livequery(function() {
    $(this).autocomplete($('#static-data').data('d').autocomplete, {
      width: 300,
      multiple: true,
      matchContains: true,
      autoFill: false,
      searchKey: 'username',
      minChars: 2,
      matchSubset: false,
      selectFirst: false,
      mustMatch: false,
      max: 10,
      buckets: [['user', $('#static-data').data('d').userAutoBucket, 'FOLLOWING'], ['user','user','OTHER USERS']],
      extraParams: {"types":['user']},
      allowNew: false,
      dataType: 'json',
      delay: 100,
      formatItem: function(row, i, max) {
        return row.formattedItem;
      },
      formatMatch: function(row, i, max) {
        return row.username;
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
// Wait for Document
$(function() {

  $('form:not(.noajax)').live('submit', function(event) {
    // Ajaxify this form

    event.preventDefault();
    $currentTarget = $(this);
    formSubmit($(this), null, null);

    return false;
  });

  /*
   * Submit and handle a form..
   */
  var formSubmit = function(form, success, error) {

    console.log('Form submit');

    $.ajax({
      type: form.attr('method'),
      url: form.attr('action'),
      data: form.serializeArray(),
      dataType: 'json',
      success: function(data) {
        if (data.result == 'error') {
          form.replaceWith(data.form);
        }
        else {
          $('#contribute').colorbox.close();
        }

        appUpdate(data);

        if (success) {
          success();
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        console.log(jqXHR)
        console.log(textStatus)
        console.log(errorThrown)
        if (jqXHR.status == 401) {
          $('#login').click()
          $('#user_email').focus()
          $('.qtip.ui-tooltip').qtip('hide')
        }
        if (error) {
          error();
        }
      }
    });

  }; // end onStateChange

}); // end onDomLoad
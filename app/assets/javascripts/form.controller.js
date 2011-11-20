// Wait for Document
$(function() {

  $('form.ajax').live('submit', function(event) {
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

    console.log(form.serializeArray());
    $.ajax({
      type: form.attr('method'),
      url: form.attr('action'),
      data: form.serializeArray(),
      dataType: 'json',
      beforeSend: function() {
        form.find('.errors').html('').hide();
        form.find('input, textarea').attr('disabled', true);
        $('#form-submitting').fadeIn(300);
      },
      success: function(data) {
        $('#form-submitting').fadeOut(300);
        form.find('input, textarea').removeAttr('disabled');

        appUpdate(data);

        if (success) {
          success();
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        $('#form-submitting').fadeOut(300);
        form.find('input, textarea').removeAttr('disabled');

        data = $.parseJSON(jqXHR.responseText)
        appUpdate(data);

        // If they need to login
        if (jqXHR.status == 401)
        {
          $('#register').click()
          $('.qtip.ui-tooltip').qtip('hide')
        }
        // If there was a form error
        else if (jqXHR.status == 422)
        {
          var $error_field = form.find('.errors');
          $error_field.show();
          $.each(data.errors, function(target_field, field_errors) {
            $.each(field_errors, function(i, error) {
              $error_field.append('<div class="error">'+target_field+' '+error+'</div>');
            })
          })
        }

        if (error) {
          error();
        }
      }
    });

  }; // end onStateChange

}); // end onDomLoad
jQuery ->
  $('.coreShareB').livequery ->
    form = $('.new_core_object_share').clone()
    form.find('.object_id').val($(this).data('d').id)
    $(this).qtip({
      content: {
        text: form
      }
      show: {
        event: 'click'
      }
      hide: {
        event: 'unfocus'
      }
      position: {
        my: 'top right'
        at: 'bottom right'
        viewport: $(window)
      }
    });

  $('.new_core_object_share').live 'submit', (event) ->
    event.preventDefault()
    formValues = $(this).serializeArray()
    $.post(
      $(this).attr('action')
      formValues
      (data) ->
        console.log(data)
    )

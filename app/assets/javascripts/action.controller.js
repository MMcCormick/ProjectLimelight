// Wait for Document
$(function() {

  // Perform an action. .ac for POST actions, .acg for GET actions.
  $('.ac').live('click', function(event) {
    $currentTarget = $this;

    var $this = $(this),
        $url = $this.attr('href') ? $this.attr('href') : $this.data('url')
        $requestType = $this.data('m');
        $payload = $this.data('d');

    event.preventDefault();

    doAction({requestType: $requestType, payload: $payload, url: $url}, null, null);

    return false;
  });

  // Perform a button action
  $('.btn-tog').live('click', function(event) {

    // Ajaxify this link
    var $this = $(this),
        $url = $this.children(':visible').data('url'),
        $requestType = $this.children(':visible').data('m'),
        $payload = $this.children(':visible').data('d');

    $currentTarget = $this;

    event.preventDefault();
    doAction({requestType: $requestType, payload: $payload, url: $url}, toggleButton, null);

    $currentTarget.fadeTo(100, .5).css('cursor', 'default');

    return false;
  });

  function toggleButton(params, data) {
    if (data.status == 'ok') {
      var target = $(data.target);
      $.each(data.toggle_classes, function(i, val) {
        target.toggleClass(val);
      })
      if (data.update_target)
      {
        $(data.update_target).html(data.update_value)
      }
    }

    $currentTarget.fadeTo(100, 1).css('cursor', 'pointer');
  }

}); // end onDomLoad
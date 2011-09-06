// Wait for Document
$(function() {

  // Perform an action. .ac for POST actions, .acg for GET actions.
  $('.ac, .acg').live('mouseup, click', function(event) {
    // Ajaxify this link
    var $this = $(this),
            url = $this.attr('href') ? $this.attr('href') : $this.data('url'),
            requestType = $this.hasClass('ac') ? 'POST' : 'GET';

    $currentTarget = $this;

    doAction(requestType, {'url': url}, null, null);
    event.preventDefault();

    return false;
  });

  // Perform a button action
  $('.btnp').live('click', function(event) {
    // Ajaxify this link
    var $this = $(this),
        url = $this.find('span:visible').data('url'),
        requestType = 'POST';

    $currentTarget = $this;
    var $payload = $this.find('span:visible').data('d');
    $payload['url'] = url;

    doAction(requestType, $payload, toggleButton, null);
    event.preventDefault();

    $currentTarget.fadeTo(100, .5).css('cursor', 'default');

    return false;
  });

  function toggleButton(params, data)
  {
    if (data.status == 'ok')
    {
      var target = $(data.target);
      $.each(data.toggle_classes, function(i, val) {
        target.toggleClass(val);
      })
    }
    else
    {
      alert('error (fill this)')
    }
    $currentTarget.fadeTo(100, 1).css('cursor', 'pointer');
  }

}); // end onDomLoad
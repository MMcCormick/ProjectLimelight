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
  $('.btn').live('click', function(event) {
    // Ajaxify this link
    var $this = $(this),
        url = $this.find('span:visible').data('url'),
        requestType = $this.find('span:visible').data('method');

    $currentTarget = $this;
    var $payload = $this.find('span:visible').data('d');
    $payload['url'] = url;

    // If there is no URL the user is probably not logged in...
    if (!$payload['url'])
    {
      $('#login').click()
      return
    }

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
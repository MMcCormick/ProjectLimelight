`
// usage: log('inside coolFunc', this, arguments);
// paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/
window.log = function(){
  log.history = log.history || [];   // store logs to an array for reference
  log.history.push(arguments);
  if(this.console) {
    arguments.callee = arguments.callee.caller;
    var newarr = [].slice.call(arguments);
    (typeof console.log === 'object' ? log.apply.call(console.log, console, newarr) : console.log.apply(console, newarr));
  }
};

// make it safe to use console.log always
(function(b){function c(){}for(var d="assert,count,debug,dir,dirxml,error,exception,group,groupCollapsed,groupEnd,info,log,timeStamp,profile,profileEnd,time,timeEnd,trace,warn".split(","),a;a=d.pop();){b[a]=b[a]||c}})((function(){try
{console.log();return window.console;}catch(err){return window.console={};}})());
`

jQuery ->

  # Clears a form or form element
  $.fn.clearForm = () ->
    this.each ->
      type = this.type
      tag = this.tagName.toLowerCase()
      if (tag == 'form')
        return $(':input',this).clearForm()
      if (type == 'text' || type == 'password' || tag == 'textarea')
        this.value = ''
      else if (type == 'checkbox' || type == 'radio')
        this.checked = false
      else if (tag == 'select')
        this.selectedIndex = -1

  # Sets the cursor to a position in an input
  $.fn.selectRange = (start, end) ->
    return @each ->
      if @setSelectionRange
        @focus()
        @setSelectionRange start, end
      else if @createTextRange
        range = @createTextRange()
        range.collapse true
        range.moveEnd 'character', end
        range.moveStart 'character', start
        range.select()

  # Automatic toggling of overlay label on inputs
  $('.lClear > input, .lClear > textarea').livequery ->
    $(@).attr 'autocomplete', 'off'

  $('.lClear label').livequery ->
    $(@).labelOver('over-apply')

  # generic tips
  $('.tip').livequery ->
    $(@).each ->
      $self = $(@)
      $self.qtip
        style:
          classes: 'ui-tooltip-shadow ui-tooltip-light'
        position:
          my: 'middle left'
          at: 'middle right'
          viewport: $(window)
        show:
          delay: 200
        hide:
          delay: 200
          fixed: true

  # future features
  $('.future').livequery ->
    $(@).css({ opacity: 0.25 }).attr('title', 'This feature will be available soon!');

  # authenticate prompt
  $('.auth').live 'click', (e) ->
    e.preventDefault()
    $('#register').click()
    return false

  # Add a border/drop shadow to buttons on hover
  $('.btn').live
    mouseenter:
      ->
        $('.btn').removeClass 'hover'
        $(@).addClass('hover')

    mouseleave:
      ->
        $(@).removeClass('hover')

  # Disables text selection (highlighting, etc)
  $('.noSelect').bind 'selectstart, click', (e) ->
    false

  # show more buttons (for showing extra text)
  $('.show-more .more').live 'click', (e) ->
    if ($(@).hasClass('on'))
      $(@).text('... show more').removeClass('on').siblings('.extra').hide()
    else
      $(@).text('hide more').addClass('on').siblings('.extra').show()

  #  onScreen jQuery plugin v0.2.1
  #  (c) 2011 Ben Pickles
  #
  #  http://benpickles.github.com/onScreen
  #
  #  Released under MIT license.
  $.expr[":"].onScreen = (elem) ->
    $window = $(window)
    viewport_top = $window.scrollTop()
    viewport_height = $window.height()
    viewport_bottom = viewport_top + viewport_height
    $elem = $(elem)
    top = $elem.offset().top
    height = $elem.height()
    bottom = top + height

    (top >= viewport_top && top < viewport_bottom) ||
    (bottom > viewport_top && bottom <= viewport_bottom) ||
    (height > viewport_height && top <= viewport_top && bottom >= viewport_bottom)
$(function() {

  jQuery.fn.extend({
    // Inserts text at the caret
    // $('#element').insertAtCaret('foo');
    insertAtCaret: function(myValue, offset) {
      return this.each(function(i) {
        if (document.selection) {
          this.focus();
          sel = document.selection.createRange();
          sel.text = myValue;
          this.focus();
        }
        else if (this.selectionStart || this.selectionStart == '0') {
          var startPos = this.selectionStart;
          var endPos = this.selectionEnd;
          var scrollTop = this.scrollTop;
          this.value = this.value.substring(0, startPos) + myValue + this.value.substring(endPos, this.value.length);
          this.focus();
          this.selectionStart = startPos + offset + myValue.length;
          this.selectionEnd = startPos + offset + myValue.length;
          this.scrollTop = scrollTop;
        } else {
          this.value += myValue;
          this.focus();
        }
      })
    },
    textBeforeCursor: function(distanceBefore) {
      var t = this[0];
      if ($.browser.msie) {
        var range = document.selection.createRange();
        var stored_range = range.duplicate();
        stored_range.moveToElementText(t);
        stored_range.setEndPoint('EndToEnd', range);
        var e = stored_range.text.length - range.text.length;
        var s = e - distanceBefore;
      }
      else {
        var e = t.selectionStart, s = e - distanceBefore;
      }
      if (s < 0) {
        s = 0;
      }
      var te = t.value.substring(s, e);
      return {start: s, end: e, text: te}
    }
  });

  // Sets the cursor to a position in an input
  $.fn.selectRange = function(start, end) {
    return this.each(function() {
      if (this.setSelectionRange) {
        this.focus();
        this.setSelectionRange(start, end);
      } else if (this.createTextRange) {
        var range = this.createTextRange();
        range.collapse(true);
        range.moveEnd('character', end);
        range.moveStart('character', start);
        range.select();
      }
    });
  };

  // Automatic clearing of help text in inputs
  $('.iclear').live('click', function() {
    if (!$(this).hasClass('cleared') && (!$(this).data('default') || $(this).val() == $(this).data('default'))) {
      $(this).addClass('active').data('default', $(this).val()).selectRange(0, 0);
    }
  })
  $('.iclear').live('blur', function() {
    if (!$.trim($(this).val()) || $(this).val() == $(this).data('default')) {
      $(this).removeClass('active cleared').val($(this).data('default'));
    }
  })
  $('.iclear').live('keydown', function() {
    if ($(this).val() == $(this).data('default')) {
      $(this).removeClass('active').val('');
    }
  })
  $('.iclear').live('keyup', function() {
    if (!$.trim($(this).val())) {
      $(this).addClass('active').val($(this).data('default')).selectRange(0, 0);
    }
  })

  // Add a border/drop shadow to buttons on hover
  $('.btn').live({
    mouseenter:
            function() {
              $('.btn').removeClass('hover');
              $(this).addClass('hover', 1000);
            },
    mouseleave:
            function() {
              $(this).removeClass('hover', 500);
            }
  })

  // Enlarge a picture in place when hovered on
  $('.enlarge').live({
    mouseenter:
            function() {
              if ($(this).hasClass('hover'))
                return;

              var target = $(this).is('a') ? $(this).find('img') : $(this);

              var newSize = 275;

              var url = target.attr('src'),
                      parts = url.split('/'),
                      dimensions = parts[2].split('-'),
                      newUrl = '/' + parts[1],
                      newDimensions = '';

              if (dimensions.length == 3) {
                newDimensions = 'w' + newSize + '-h' + newSize + '-' + dimensions[2];
              }
              else if (dimensions.length == 2) {
                newDimensions = 'h' + newSize;
              }
              else {

              }

              newUrl += '/' + newDimensions;
              $.each(parts, function(index, val) {
                if (index > 2) {
                  newUrl += '/' + val;
                }
              })

              $(this).oneTime(500, "enlarge-picture", function() {
                var newTarget = $(this).clone();

                newTarget.addClass('hover')
                        .css({position: 'absolute', left: $(this).offset().left - target.width() - 30, top: $(this).offset().top + $(this).height() - target.height()})

                if (newTarget.is('a')) {
                  newTarget.find('img').attr('src', newUrl)
                }
                else {
                  newTarget.attr('src', newUrl);
                }

                newTarget.oneTime(150, "show-enlarged-picture", function() {
                  newTarget.appendTo('body');
                })
              })
            },
    mouseleave:
            function() {
              $(this).stopTime();
            }
  })

  $('.enlarge.hover').live({
    mouseleave:
            function() {
              $(this).remove();
            }
  })

  // Disables text selection (highlighting, etc)
  $('.noSelect').bind('selectstart, click', function() {
    return false;
  })//No text selection on elements with a class of 'noSelect'

  // onScreen jQuery plugin v0.2.1
  // (c) 2011 Ben Pickles
  //
  // http://benpickles.github.com/onScreen
  //
  // Released under MIT license.
  $.expr[":"].onScreen = function(elem) {
    var $window = $(window)
    var viewport_top = $window.scrollTop()
    var viewport_height = $window.height()
    var viewport_bottom = viewport_top + viewport_height
    var $elem = $(elem)
    var top = $elem.offset().top
    var height = $elem.height()
    var bottom = top + height

    return (top >= viewport_top && top < viewport_bottom) ||
            (bottom > viewport_top && bottom <= viewport_bottom) ||
            (height > viewport_height && top <= viewport_top && bottom >= viewport_bottom)
  }
})
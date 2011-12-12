function catchKey(e)
{
  var keyCode;
  if(!e)
    e = window.event;
  if(e.keyCode)
    keyCode = e.keyCode;
  else
    keyCode = e.charCode;
  return keyCode;
}

/*
 * jQuery plugin: fieldSelection - v0.1.0 - last change: 2006-12-16
 * (c) 2006 Alex Brem <alex@0xab.cd> - http://blog.0xab.cd
 */
(function() {
  var c = {getSelection:function() {
    var e = this.jquery ? this[0] : this;
    return(('selectionStart'in e && function() {
      var l = e.selectionEnd - e.selectionStart;
      return{start:e.selectionStart,end:e.selectionEnd,length:l,text:e.value.substr(e.selectionStart, l)}
    }) || (document.selection && function() {
      e.focus();
      var r = document.selection.createRange();
      if (r == null) {
        return{start:0,end:e.value.length,length:0}
      }
      var a = e.createTextRange();
      var b = a.duplicate();
      a.moveToBookmark(r.getBookmark());
      b.setEndPoint('EndToStart', a);
      return{start:b.text.length,end:b.text.length + r.text.length,length:r.text.length,text:r.text}
    }) || function() {
      return{start:0,end:e.value.length,length:0}
    })()
  },replaceSelection:function() {
    var e = this.jquery ? this[0] : this;
    var a = arguments[0] || '';
    return(('selectionStart'in e && function() {
      e.value = e.value.substr(0, e.selectionStart) + a + e.value.substr(e.selectionEnd, e.value.length);
      return this
    }) || (document.selection && function() {
      e.focus();
      document.selection.createRange().text = a;
      return this
    }) || function() {
      e.value += a;
      return this
    })()
  }};
  jQuery.each(c, function(i) {
    jQuery.fn[i] = this
  })
})();

// Basic settings
var settings = [
  {
    type          : 'user',
    trigger       : '@',
    autocomplete  : $('#static-data').data('d').autocomplete,
    match         : '<b>$1</b>',
    selectFirst   : true,
    mustMatch     : true,
    highlight     : 'user-mention',
    allowNew      : false,
    bucket        : $('#static-data').data('d').userAutoBucket,
    bucketType    : 'user',
    bucketName    : 'USERS'
  },
  {
    type          : 'topic',
    trigger       : '#',
    autocomplete  : $('#static-data').data('d').autocomplete,
    match         : '<b>$1</b>',
    selectFirst   : true,
    mustMatch     : false,
    highlight     : 'topic-mention',
    allowNew      : true,
    bucket        : 'topic',
    bucketType    : 'topic',
    bucketName    : 'TOPICS'
  }
]

// Data
var fields = [];

// Hooks
(function($) {
  $.fn.extend({
    mentionable: function() {
      return this.each(function(index, val) {
        new $.Mentionable($(val), index);
      });
    },
    mentionAdded: function(handler) {
      return this.bind("mentionAdded", handler);
    },
    mentionRemoved: function(handler) {
      return this.bind("mentionRemoved", handler);
    }
  })

  $.Mentionable = function(input, index) {
    var under = $('<div class="under"></div>'),
        autocomplete = $('<input type="text" class="autocomplete" />'),
        hidden = input.parent().find('.data');

    input.before(under);
    input.after(autocomplete);

    var mentionField = new field(input, autocomplete, under, hidden);

    input.bind('keypress',
    function(e) { // Handle keypresses within mentionField fields that need to fire before keyup()
      var keyCode = catchKey(e);

      // Intercept enter key, tab, and pound keys
      if ((keyCode == 13 || keyCode == 9 || (keyCode == 35 || keyCode == 16 || (e.shiftKey && e.keyCode == 51))) && mentionField.state >= 0) {
        if (e.preventDefault) {
          e.preventDefault();
        } else {
          e.cancelBubble = true;
          e.returnValue = false;
        }

        if (keyCode == 35 || keyCode == 16 || (e.shiftKey && e.keyCode == 51))
        {
          mentionField.useShortName = true;
        }

        active = mentionField.autocompleteLoaded && $('.ac_results .ac_over').length > 0 ? $('.ac_results .ac_over') : false;
        if (active) {
          active.click();
        } else if (settings[mentionField.mode].allowNew) {
          mentionField.addMention(mentionField.state - settings[mentionField.mode].trigger.length, mentionField.caret, null, mentionField.type, null);
        }

        mentionField.input.focus().setCursorPosition(mentionField.caret);
      }
    }).bind('keydown',
    function(e) { // Handle keypresses within mentionField fields that need to fire before keyup() but don't fire on keypress()
      // Intercept arrow keys
      var keyCode = catchKey(e);

      if ((keyCode == 38 || keyCode == 40) && mentionField.autocompleteLoaded) {
        mentionField.autocomplete.trigger(e)
        if (e.preventDefault) {
          e.preventDefault();
        } else {
          e.cancelBubble = true;
          e.returnValue = false;
        }
      } else if ($(this).val() == mentionField.value && $(this).getSelection().start != mentionField.caret) {
        // Detect caret movement (left/right arrow or mouse click movement)
        mentionField.unload();
      }
    }).bind('click keyup', function(e) { // Handle keypresses within mentionField fields
      index = $(this).data('index');

      // Update caret position
      mentionField.caret = $(this).getSelection().start;

      // Detect insertion/deletion & move mentionFields if necessary
      var delta = $(this).val().length - mentionField.value.length;
      var remove = [];
      $.each(mentionField.mentions, function(i, mention) {
        if(delta >= 0) {
          // Insertion
          if(mention.pos >= mentionField.caret-delta) {
            mention.pos += delta;
          }
        } else {
          // Deletion
          if(mention.pos >= mentionField.caret && mention.pos < mentionField.caret-delta) {
            remove.push(i);
          } else if(mention.pos < mentionField.caret && mention.pos+mention.length() > mentionField.caret) {
            // Revert to editing state; re-add trigger; update caret;
            remove.push(i);
            mentionField.input.val(mentionField.input.val().substr(0, mention.pos)+settings[mention.mode].trigger+mentionField.input.val().substr(mention.pos));
            mentionField.caret += settings[mention.mode].trigger.length;
            delta += settings[mention.mode].trigger.length;
            mentionField.input.setCursorPosition(mentionField.caret);
            mentionField.state = mention.pos+settings[mention.mode].trigger.length;
            mentionField.mode = mention.mode;
          } else if(mention.pos >= mentionField.caret-delta) {
            mention.pos += delta;
          }
        }
      });
      var sub = 0;
      var memory = mentionField.mentions;
      $.each(remove.sort(), function(irr, rdex) {
        mentionField.removeMention(rdex - sub);
        memory = mentionField.mentions;
        sub++;
      });
      mentionField.mentions = memory;

      // Update value
      mentionField.value = $(this).val();

      // Check for the trigger string
      $.each(settings, function(i, s) {
        if (mentionField.value.substr(mentionField.caret - s.trigger.length, s.trigger.length) == s.trigger) {
          mentionField.state = mentionField.caret;
          mentionField.mode = i;
          return false;
        }
      });

      // Check for deleting the trigger string
      if (mentionField.caret < mentionField.state) {
        mentionField.unload();
      }

      var type = mentionField.type;
      // Get mentionField
      if (mentionField.state >= 0) {
        mentionField.type = $(this).val().substr(mentionField.state, mentionField.caret - mentionField.state);
      }

      // Autocomplete
      if (type != mentionField.type && mentionField.type.length > 0 && mentionField.state >= 0) {
        if (!mentionField.autocompleteLoaded) {
          mentionField.load_autocomplete()
        }
        mentionField.autocomplete.searchFor(mentionField.type);
      }

      // Update highlighting
      mentionField.highlight();
    });

  }

  $.fn.setCursorPosition = function(pos) {
    if ($(this).get(0).setSelectionRange) {
      $(this).get(0).setSelectionRange(pos, pos);
    } else if ($(this).get(0).createTextRange) {
      var range = $(this).get(0).createTextRange();
      range.collapse(true);
      range.moveEnd('character', pos);
      range.moveStart('character', pos);
      range.select();
    }
  }

  Array.prototype.remove = function(i) {
    var rest = this.slice(i + 1 || this.length);
    this.length = i < 0 ? this.length + i : i;
    return this.push.apply(this, rest);
  };

  // Represents a mention
  function mention(pos, id, text, data, mode, short_name) {
    this.pos = pos;
    this.id = id;
    this.text = text;
    this.data = data;
    this.mode = mode;
    this.short_name = short_name;
    this.length = function() {
      return this.text.length;
    }
  }

  // Represents a mention field
  function field(input, autocomplete, under, data) {
    this.mentions = [];
    this.type = '';
    this.caret = input.is(':visible') ? input.getSelection().start : 0;
    this.state = -1; // (-1) = Typing; (>= 0) = mention starting at this position
    this.mode = 0; // (-1) = Typing; (>= 0) = index of settings arry to use
    this.xhr = false;
    this.input = input;
    this.autocomplete = autocomplete;
    this.autocompleteLoaded = false;
    this.under = under;
    this.data = data;
    this.callbacks = {};
    this.value = input.val();
    this.useShortName = false;

    // Adds a mention to this field (and tidy up after)
    this.addMention = function(start, end, id, text, data) {
      short_name = false;
      if (this.useShortName)
      {
        if (data['data']['short_name'])
        {
          short_name = data['data']['short_name'];
          text = '#'+short_name;
          this.value = short_name;
        }
        else
        {
          return false;
        }
      }

      this.value = this.input.val().substr(0, start) + text + this.input.val().substr(end);
      var delta = this.value.length - this.input.val().length;

      this.input.val(this.value);

      this.mentions.push(new mention(start, id, text, data, this.mode, short_name));

      $.each(this.mentions, function(i, mention) {
        if (mention.pos > start) {
          mention.pos += delta;
        }
      });

      // Unload autocompleter
      this.unload();

      // Update highlighting
      this.highlight();

      // Move the caret
      var caret = start + text.length;
      this.input.focus().setCursorPosition(caret);
      this.caret = caret;

      this.input.trigger('mentionAdded', data);
    }

    // Removes a mention from this field
    this.removeMention = function(index) {
      this.input.trigger('mentionRemoved', index);
      this.mentions.splice(index, 1);
    }

    // Loads autocompleter
    this.load_autocomplete = function() {
      var mention = this

      this.autocomplete.autocomplete(settings[this.mode].autocomplete, {
        minChars: 2,
        width: 500,
        matchContains: true,
        matchSubset: false,
        autoFill: false,
        selectFirst: settings[this.mode].selectFirst,
        mustMatch: settings[this.mode].mustMatch,
        searchKey: 'term',
        max: 10,
        buckets: [[settings[this.mode].bucketType, settings[this.mode].bucket, settings[this.mode].bucketName]],
        extraParams: {"types":[settings[this.mode].bucket]},
        allowNew: settings[this.mode].allowNew,
        allowNewName: settings[this.mode].bucketType,
        allowNewType: settings[this.mode].bucketType,
        dataType: 'json',
        delay: 150,
        formatItem: function(row, i, max) {
          return row.formattedItem;
        },
        formatMatch: function(row, i, max) {
          return row.term;
        },
        formatResult: function(row) {
          return row.term;
        }
      }).result(function(event, data, formatted) {
        if (data)
        {
          var passData = null,
              passId = null;
          if (data.id)
          {
            passData = data;
            passId = data.id;
          }

          mention.addMention(mention.state - settings[mention.mode].trigger.length, mention.caret, passId, data.term, passData);
        }
      });
      this.autocompleteLoaded = true;
    }

    // Unloads autocompleter
    this.unload = function() {
      this.autocomplete.unautocomplete();
      this.autocompleteLoaded = false;
      this.state = -1;
      this.type = '';
    }

    // Add highlighting (also calls ".store()")
    this.highlight = function() {
      this.mentions.sort(function(a, b) {
        return a.pos - b.pos;
      });
      var html = this.value;
      var add = 0;
      var addstate = 0;
      var s = this.state;
      var m = this.mode;
      $.each(this.mentions, function(i, mention) {
        if (mention.short_name)
        {
          html = '#' + html;
        }
        else
        {
          var sub = html.length;
          html = html.substr(0, mention.pos + add) + '<b class="' + settings[mention.mode].highlight + '">' + mention.text + '</b>' + html.substr(mention.pos + add + mention.length());
          add += html.length - sub;
          if (mention.pos <= s) {
            addstate += html.length - sub;
          }
        }
      });

      if (this.state >= 0) {
        html = html.substr(0, this.state - settings[this.mode].trigger.length + addstate) + '<b>' + settings[this.mode].trigger + this.type + '</b>' + html.substr(this.caret + addstate);
      }
      this.under.html(html);
      this.store();
    }

    // Update hidden field
    this.store = function() {
      this.mentions.sort(function(a, b) {
        return a.pos - b.pos;
      });
      var html = this.value;
      var add = 0;
      $.each(this.mentions, function(i, mention) {
        var sub = html.length;
        if (mention.short_name)
        {
          html = html.substr(0, mention.pos + add) + settings[mention.mode].trigger + mention.short_name + html.substr(mention.pos + add + mention.length());
        }
        else
        {
          html = html.substr(0, mention.pos + add) + settings[mention.mode].trigger + '[' + (mention.id == null ? '' : mention.id + '#') + mention.text + ']' + html.substr(mention.pos + add + mention.length());
        }
        add += html.length - sub;
      });
      this.data.val(html);
    }

    // Store some data
    var index = $('.mention').index(input);
    $.each([input, under], function(i, el) {
      el.data('index', index);
    });
  }

})(jQuery);
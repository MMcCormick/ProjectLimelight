// Basic settings
var settings = [{
	type					: 'user',
	trigger				: '@',
	autocomplete	: 'u/ac',
	match					: '<b>$1</b>',
	highlight			: 'user-mention'
},{
	type					: 'topic',
	trigger				: '#',
	autocomplete	: 't/ac',
	match					: '<b>$1</b>',
	highlight			: 'topic-mention'
}]

// Data
var fields = [];

// Hooks
(function($){
  $.fn.mentionAdd = function(type, callback) {
		if(typeof(callback) != "function") {
			callback = type;
			type = '';
		}
		this.each(function() {
			index = $(this).data('index');
			fields[index].callbacks['add'+type.charAt(0).toUpperCase()+type.slice(1).toLowerCase()] = callback;
		});
  };
})(jQuery);

// Miscellanious functions
new function($) {
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
}(jQuery);
Array.prototype.remove = function(i) {
  var rest = this.slice(i + 1 || this.length);
  this.length = i < 0 ? this.length + i : i;
  return this.push.apply(this, rest);
};
/*
 * jQuery plugin: fieldSelection - v0.1.0 - last change: 2006-12-16
 * (c) 2006 Alex Brem <alex@0xab.cd> - http://blog.0xab.cd
 */
(function(){var c={getSelection:function(){var e=this.jquery?this[0]:this;return(('selectionStart'in e&&function(){var l=e.selectionEnd-e.selectionStart;return{start:e.selectionStart,end:e.selectionEnd,length:l,text:e.value.substr(e.selectionStart,l)}})||(document.selection&&function(){e.focus();var r=document.selection.createRange();if(r==null){return{start:0,end:e.value.length,length:0}}var a=e.createTextRange();var b=a.duplicate();a.moveToBookmark(r.getBookmark());b.setEndPoint('EndToStart',a);return{start:b.text.length,end:b.text.length+r.text.length,length:r.text.length,text:r.text}})||function(){return{start:0,end:e.value.length,length:0}})()},replaceSelection:function(){var e=this.jquery?this[0]:this;var a=arguments[0]||'';return(('selectionStart'in e&&function(){e.value=e.value.substr(0,e.selectionStart)+a+e.value.substr(e.selectionEnd,e.value.length);return this})||(document.selection&&function(){e.focus();document.selection.createRange().text=a;return this})||function(){e.value+=a;return this})()}};jQuery.each(c,function(i){jQuery.fn[i]=this})})();

// Represents a mention
function mention(pos, id, text, data, mode) {
	this.pos = pos;
	this.id = id;
	this.text = text;
	this.data = data;
	this.mode = mode;
	this.length = function() {
		return this.text.length;
	}
}

// Represents a mention field
function field(input, select, under, data) {
  this.mentions = [];
	this.type = '';
  this.caret = input.is(':visible') ? input.getSelection().start : 0;
  this.state = -1; // (-1) = Typing; (>= 0) = mention starting at this position
	this.mode = 0; // (-1) = Typing; (>= 0) = index of settings arry to use
  this.xhr = false;
  this.input = input;
	this.select = select;
	this.under = under;
	this.data = data;
	this.callbacks = {};
	this.value = input.val();

  // Adds a mention to this field (and tidy up after)
	this.addMention = function(start, end, id, text, data) {
		this.value = this.input.val().substr(0, start)+text+this.input.val().substr(end);
		var delta = this.value.length-this.input.val().length;
		
		this.input.val(this.value);
		this.mentions.push(new mention(start, id, text, data, this.mode));
		
		$.each(this.mentions, function(i, mention) {
			if(mention.pos > start) {
				mention.pos += delta;
			}
		});
		
		// Move the caret
		var caret = start+text.length;
		this.input.setCursorPosition(caret);
		this.caret = caret;
		
		// Unload autocompleter
		this.unload();
		
		// Update highlighting
		this.highlight();
		
		// Callback
		var cbData = {
			'id'		: id,
			'text'	: text,
			'data'	: data
		}
		if(this.callbacks['add']) {
			this.callbacks['add'].call(this, cbData);
		}
		var cbMode = this.callbacks['add'+settings[this.mode].type.charAt(0).toUpperCase()+settings[this.mode].type.slice(1).toLowerCase()];
		if(cbMode) {
			cbMode.call(this, cbData);
		}
	}
	
	// Removes a mention from this field
	this.removeMention = function(index) {
		this.mentions.splice(index, 1);
	}
	
	// Unloads autocompleter
	this.unload = function() {
		this.select.fadeOut(150);
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
			var sub = html.length;
			html = html.substr(0, mention.pos+add)+'<b class="'+settings[mention.mode].highlight+'">'+mention.text+'</b>'+html.substr(mention.pos+add+mention.length());
			add += html.length-sub;
			if(mention.pos <= s) {
				addstate += html.length-sub;
			}
		});
		if(this.state >= 0) {
			html = html.substr(0, this.state-settings[this.mode].trigger.length+addstate)+'<b>'+settings[this.mode].trigger+this.type+'</b>'+html.substr(this.caret+addstate);
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
			html = html.substr(0, mention.pos+add)+settings[mention.mode].trigger+'['+(mention.id == null ? '' : mention.id+'#')+mention.text+']'+html.substr(mention.pos+add+mention.length());
			add += html.length-sub;
		});
		this.data.val(html);
	}
	
	// Store some data
	var index = $('.mention').index(input);
	$.each([input, select, under], function(i, el) {
		el.data('index', index);
	});
}

$(document).ready(function() {
	// Initialize object representations of each mention field
	$('.mention').each(function(index) {
		var parent = $(this).parent();
		fields[index] = new field($(this), $('.select', $(this).parent()), $('.under', $(this).parent()), $('.data', $(this).parent()));
	});

	// Handle keypresses within mention fields that need to fire before keyup()
	$('.mention').keypress(function(e) {
    // Intercept enter key
		if(e.which == 13 && fields[index].state >= 0) {
      var active = $('.active', fields[index].select);
      if(active.size()) {
        active.click();
			} else {
				fields[index].addMention(fields[index].state-settings[fields[index].mode].trigger.length, fields[index].caret, null, fields[index].type, null);
			}
			if(e.preventDefault){
				e.preventDefault();
			} else {
				e.cancelBubble = true;
				e.returnValue = false;
			}
		}
	});

	// Handle keypresses within mention fields that need to fire before keyup() but don't fire on keypress()
	$('.mention').keydown(function(e) {
		// Intercept arrow keys
		if(((e.which == 38 && $('.active', fields[index].select).size() > 0) || e.which == 40) && fields[index].select.css('display') == 'block') {
			var dir = e.which == 38 ? -1 : 1;
			var options = $('.option', fields[index].select);
			var eq = Math.min(options.size()-1, Math.max($('.active', fields[index].select).index()+dir, 0));
			options.removeClass('active').eq(eq).addClass('active');
			if(e.preventDefault){
				e.preventDefault();
			} else {
				e.cancelBubble = true;
				e.returnValue = false;
			}
		} else if($(this).val() == fields[index].value && $(this).getSelection().start != fields[index].caret) {
			// Detect caret movement (left/right arrow or mouse click movement)
			fields[index].unload();
		}
	});

	// Handle keypresses within mention fields
	$('.mention').bind('click keyup', function(e) {
		index = $(this).data('index');

		// Update caret position
		fields[index].caret = $(this).getSelection().start;

		// Detect insertion/deletion & move mentions if necessary
		var delta = $(this).val().length - fields[index].value.length;
		var remove = [];
		$.each(fields[index].mentions, function(i, mention) {
			if(delta >= 0) {
				// Insertion
				if(mention.pos >= fields[index].caret-delta) {
					mention.pos += delta;
				}
			} else {
				// Deletion
				if(mention.pos >= fields[index].caret && mention.pos < fields[index].caret-delta) {
					remove.push(i);
				} else if(mention.pos < fields[index].caret && mention.pos+mention.length() > fields[index].caret) {
					// Revert to editing state; re-add trigger; update caret;
					remove.push(i);
					fields[index].input.val(fields[index].input.val().substr(0, mention.pos)+settings[mention.mode].trigger+fields[index].input.val().substr(mention.pos));
					fields[index].caret += settings[mention.mode].trigger.length;
					delta += settings[mention.mode].trigger.length;
					fields[index].input.setCursorPosition(fields[index].caret);
					fields[index].state = mention.pos+settings[mention.mode].trigger.length;
					fields[index].mode = mention.mode;
				} else if(mention.pos >= fields[index].caret-delta) {
					mention.pos += delta;
				}
			}
		});
		var sub = 0;
		var memory = fields[index].mentions;
		$.each(remove.sort(), function(irr, rdex) {
			fields[index].removeMention(rdex-sub);
			memory = fields[index].mentions;
			sub++;
		});
		fields[index].mentions = memory;

		// Update value
		fields[index].value = $(this).val();

		// Check for the trigger string
		$.each(settings, function(i, s) {
			if(fields[index].value.substr(fields[index].caret-s.trigger.length, s.trigger.length) == s.trigger) {
				fields[index].state = fields[index].caret;
				fields[index].mode = i;
				return false;
			}
		});

		// Check for deleting the trigger string
		if(fields[index].caret < fields[index].state) {
			fields[index].unload();
		}

		var type = fields[index].type;
		// Get mention
		if(fields[index].state >= 0) {
			fields[index].type = $(this).val().substr(fields[index].state, fields[index].caret-fields[index].state);
		}

		// Autocomplete
    if(type != fields[index].type && fields[index].type.length > 2 && fields[index].state >= 0) {
			if(fields[index].xhr) {
				fields[index].xhr.abort();
			}
			fields[index].xhr = $.get(settings[fields[index].mode].autocomplete, {
				q : fields[index].type
			}, function(data) {
				fields[index].select.html('');
				$.each(data, function(id) {
          var rx = new RegExp('('+fields[index].type+')', 'gi')
					fields[index].select.append($('<li class="option">'+data[id].formattedItem+'</li>').data({
						'id' : data[id].id,
						'text' : data[id].name,
						'data' : data[id].data
					}));
				});
				fields[index].select.fadeIn(150);
			});
		}

		// Update highlighting
		fields[index].highlight();
	});

	// Handle autocomplete selection
	$('.select .option').live('click', function() {
		var index = $(this).parent().data('index');
		fields[index].addMention(fields[index].state-settings[fields[index].mode].trigger.length, fields[index].caret, $(this).data('id'), $(this).data('text'), $(this).data('data'));
	});
});
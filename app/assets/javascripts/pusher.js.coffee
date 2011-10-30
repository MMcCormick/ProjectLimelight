jQuery ->

  $('.teaser.grid,.teaser.list').each (index, val) ->
    id = $(@).data('id')
    channel = pusher.subscribe(id);
    channel.bind 'popularity_change', (data) ->
      $('.p_'+id).text(data.popularity)

  if $('#static-data').data('d').myId != 0
    channel = pusher.subscribe($('#static-data').data('d').myId+"_private");

  $('.user-subscribe').each (index, val) ->
    id = $(@).data('id')
    channel = pusher.subscribe(id+'_public');
    channel.bind 'popularity_change', (data) ->
      $('.p_'+id).text(data.popularity)
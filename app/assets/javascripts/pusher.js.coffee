jQuery ->

  $('.teaser.grid,.teaser.list').each (index, val) ->
    id = $(@).data('id')
    channel = pusher.subscribe(id);
    channel.bind 'popularity_changed', (data) ->
      pt = $('.pt_'+id)
      pt.text(parseFloat(pt.text())+data.change)
      $('.p_'+id).text(parseInt(pt.text()))
      change = if data.change > 0 then '+'+data.change else data.change
      $('.pc_'+id).text(change).fadeIn 200, ->
        $(@).oneTime 500, 'update_popularity', ->
          $(@).fadeOut(200).text('')

  if $('#static-data').data('d').myId != 0
    channel = pusher.subscribe($('#static-data').data('d').myId+"_private");

  $('.user-subscribe').each (index, val) ->
    id = $(@).data('id')
    channel = pusher.subscribe(id);
    channel.bind 'popularity_changed', (data) ->
      $('.pt_'+id).text(parseInt($('.pt_'+id).text())+parseInt(data.change))
      $('.p_'+id).text(parseInt($('.pt_'+id).text()))
jQuery ->

  $('[data-push]').each (index, val) ->
    id = $(@).data('push')
    channel = pusher.subscribe(id);

    channel.bind 'popularity_changed', (data) ->
      target = $('.p_'+data.id)
      target.data('pt', parseFloat(target.data('pt'))+data.change)
      target.text(parseInt(target.data('pt')))
      change = if data.change > 0 then '+'+(Math.round(data.change*10) / 10) else Math.round(data.change*10) / 10
      $('.pc_'+data.id).text(change).fadeIn 100, ->
        $(@).oneTime 500, 'update_popularity', ->
          $(@).fadeOut(100).text('')

    channel.bind 'notification', (data) ->
      createGrowl(false, data.message, '', 'green');
#jQuery ->
#
#  $('[data-push]').each (index, val) ->
#    id = $(@).data('push')
#    channel = pusher.subscribe(id);
#
#    channel.bind 'popularity_changed', (data) ->
#      target = $('.p_'+data.id)
#      target.data('pt', parseFloat(target.data('pt'))+data.change)
#      target.find('span').text(parseInt(target.data('pt')))
#      change = if data.change > 0 then '+'+(Math.round(data.change*10) / 10) else Math.round(data.change*10) / 10
#      $('.pc_'+data.id).text(change).fadeIn 100, ->
#        $(@).oneTime 500, 'update_popularity', ->
#          $(@).fadeOut(100).text('')
#
#    channel.bind 'new_talk', (data) ->
#      target = $('.teaser[data-push="'+data.id+'"]:not(.hover)')
#      if data.count == 1
#        text = data.count+' person is talking about this'
#      else
#        text = data.count+' people are talking about this'
#      target.find('.talking').text(text)
#      target.find('.public').html(data.html).show().effect('highlight', {color:'#88B42C'}, 1500)
#
#    channel.bind 'notification', (data) ->
#      createGrowl(false, data.message, 'Notification', 'green');
module NotificationsHelper
  def triggered_users_text_list(triggered_by, base='')
    string = ''
    triggered_by.each_with_index do |user, i|
      if i == triggered_by.length - 1 && triggered_by.length > 1
        string += ' and '
      end
      string += user_link(user, nil, base)
      if i < triggered_by.length - 1 && triggered_by.length > 2
        string += ', '
      end
    end
    string.html_safe
  end

  def action_text(notification, base='')
    case notification.type.to_sym
      when :follow
        'is following you'
      when :also # also signifies that someone has also responded to something your responded to
        "also replied to <a href='#{base+user_path(notification.object_user)}'>#{notification.object_user.username}'s</a> <a href='#{base+talk_path(notification.object)}##{notification.object.comment_id}'>comment</a> on the #{notification.object.type.downcase} <a href='#{base+post_path(notification.object)}'>#{notification.object.name}</a>".html_safe
      when :mention
        "mentioned you in their talk <a href='#{base+talk_path(notification.object)}'>#{notification.object.name}</a>".html_safe
      when :comment
        if notification.object.comment_id
          #name = notification.object_user.id == current_user.id ? 'your' : "<a href='#{base+user_path(notification.object_user)}'>#{notification.object_user.username}'s</a>"
          "replied to your <a href='#{base+talk_path(notification.object)}'>comment</a> on the #{notification.object.type.downcase} <a href='#{base+post_path(notification.object)}'>#{notification.object.name}</a>".html_safe
        else
          "replied to your talk <a href='#{base+talk_path(notification.object)}'>#{notification.object.name}</a>".html_safe
        end
      else
        "did something weird... this is a mistake and the Limelight team has been notified to fix it!"
    end
  end

  def pretty_day(time)
    a = (Chronic.parse('today at 11:59pm')-time).to_i

    case a
      when 0..86400 then 'Today'
      when 86401..172800 then 'Yesterday'
      when 172801..518400 then time.strftime("%A") # just output the day for anything in the last week
      else time.strftime("%B %d")
    end
  end
end
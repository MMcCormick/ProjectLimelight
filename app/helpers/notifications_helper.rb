module NotificationsHelper
  def triggered_users_text_list(triggered_by)
    string = ''
    triggered_by.each_with_index do |user, i|
      if i == triggered_by.length - 1 && triggered_by.length > 1
        string += ' and '
      end
      string += user_link user
      if i < triggered_by.length - 1 && triggered_by.length > 2
        string += ', '
      end
    end
    string.html_safe
  end

  def pretty_time(time)
    a = (Time.now-time).to_i

    case a
      when 0..86400 then 'Today'
      when 86401..172800 then 'Yesterday'
      when 172801..518400 then time.strftime("%A") # just output the day for anything in the last week
      else time.strftime("%B %d")
    end
  end
end
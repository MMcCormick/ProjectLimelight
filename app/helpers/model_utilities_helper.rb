module ModelUtilitiesHelper

  include ActionView::Helpers::DateHelper

  def pretty_time(date)
    pretty = time_ago_in_words(date, false).sub('about', '')+ ' ago'
    pretty == 'Today ago' ? 'just now' : pretty
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
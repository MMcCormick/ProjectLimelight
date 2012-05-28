class RootPost
  include Mongoid::Document
  include Mongoid::CachedJson

  # push_item is the pushed post FeedUserItem, FeedLikeItem, etc
  attr_accessor :root, :push_item, :like_responses, :activity_responses, :public_responses, :personal_responses, :public_talking, :personal_talking

  def initialize
    @like_responses = []
    @activity_responses = []
    @public_responses = []
    @personal_responses = []
    @push_item = nil
  end

  def generate_reasons(reasons)
    pretty_reasons = []
    reasons.each do |item|
      case item['t']
        when 'lk' # follwed user liked this post
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> liked this"
        when 'm' # you are mentioned
          pretty_reasons << "You were mentioned in this post"
        when 'fu' # followed user posted this post
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> posted this"
        when 'ft' # followed topic mentioned
          pretty_reasons << "You follow <a href='#{item['s']}' class='tlink' data-id='#{item['id']}'>#{item['n']}</a>"
        when 'frt' # topic related to a followed topic mentioned (pull from relation only)
          pretty_reasons << "You follow <a href='#{item['s']}' class='tlink' data-id='#{item['id']}'>#{item['n']}</a>, which is connected to <a href='#{item['s2']}' class='tlink' data-id='#{item['id2']}'>#{item['n2']}</a>"
      end
    end
    pretty_reasons
  end

  def as_json(options={})
    {
            :id => root.id.to_s,
            :public_talking => public_talking,
            :personal_talking => personal_talking,
            :root => root.as_json(options),
            :like_responses => like_responses.map {|r| r.as_json(options)},
            :activity_responses => activity_responses.map {|r| r.as_json(options)},
            :public_responses => public_responses.map {|r| r.as_json(options)},
            :personal_responses => personal_responses.map {|r| r.as_json(options)},
            :reasons => push_item ? generate_reasons(push_item.reasons) : []
    }
  end
end
class RootPost
  include Mongoid::Document
  include Mongoid::CachedJson

  # push_item is the pushed post FeedUserItem, FeedLikeItem, etc
  attr_accessor :root, :push_item, :like_responses, :activity_responses, :feed_responses

  def initialize
    @like_responses = []
    @activity_responses = []
    @feed_responses = []
    @push_item = nil
  end

  def generate_reasons(reasons)
    pretty_reasons = []
    reasons.each do |item|
      case item['t']
        when 'lk' # follwed user liked this post
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> liked #{root.class.name}"
        when 'lkt' # follwed user liked a talk about this post
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> liked a talk about this #{root.class.name}"
        when 'm' # you are mentioned
          pretty_reasons << "You were mentioned in this #{root.class.name}"
        when 'mt' # you are mentioned by somebody talking about this root
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> mentioned you in a talk about this #{root.class.name}"
        when 'fu' # followed user posted this post
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> posted this #{root.class.name}"
        when 'fut' # followed user posted a talk about this root
          pretty_reasons << "<a href='/users/#{item['s']}' class='ulink' data-id='#{item['id']}'>#{item['n']}</a> talked about this #{root.class.name}"
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
            :root => root.as_json(options),
            :like_responses => like_responses.map {|r| r.as_json(options)},
            :activity_responses => activity_responses.map {|r| r.as_json(options)},
            :feed_responses => feed_responses.map {|r| r.as_json(options)},
            :reasons => push_item && root.class.name != 'Topic' ? generate_reasons(push_item.reasons) : []
    }
  end
end
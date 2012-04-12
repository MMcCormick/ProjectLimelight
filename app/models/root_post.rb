class RootPost
  attr_accessor :root, :repost_responses, :activity_responses, :public_responses, :personal_responses, :public_talking, :personal_talking

  def initialize
    @repost_responses = []
    @activity_responses = []
    @public_responses = []
    @personal_responses = []
  end

  def as_json(options={})
    {
            :id => root.id.to_s,
            :public_talking => public_talking,
            :personal_talking => personal_talking,
            :root => root.as_json(options),
            :repost_responses => repost_responses.map {|r| r.as_json(options)},
            :activity_responses => activity_responses.map {|r| r.as_json(options)},
            :public_responses => public_responses.map {|r| r.as_json(options)},
            :personal_responses => personal_responses.map {|r| r.as_json(options)}
    }
  end
end
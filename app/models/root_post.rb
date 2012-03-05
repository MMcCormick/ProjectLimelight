class RootPost
  attr_accessor :root, :like_responses, :public_responses, :personal_responses, :public_talking, :personal_talking

  def initialize
    @like_responses = []
    @public_responses = []
    @personal_responses = []
  end
end
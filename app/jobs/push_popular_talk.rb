class PushPopularTalk

  @queue = :medium

  def self.perform(talk_id)
    talk = Post.find(talk_id)
    talk.push_popular_talk if talk
  end
end
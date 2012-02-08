class PushPopularTalk

  @queue = :feeds

  def self.perform(talk_id)
    talk = CoreObject.find(talk_id)
    talk.push_popular_talk if talk
  end
end
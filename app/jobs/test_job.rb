class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()

    User.all.each do |u|
      u.topic_activity_recalculate
      u.topic_likes_recalculate
      u.save
    end

  end
end
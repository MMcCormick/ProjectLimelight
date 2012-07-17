class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()
    users = User.all

    users.each do |user|
      user.topic_activity_recalculate()
      user.save
    end

  end
end
class TestJob
  include Resque::Plugins::UniqueJob
  @queue = :fast

  def self.perform()
    users = User.all

    users.each do |user|
      user.topic_activity_recalculate()
      user.save

      shares = PostMedia.where("shares.user_id" => user.id)
      shares.each do |share|
        s = share.get_share(user.id)
        if s
          s.topic_mentions.each do |t|
            Neo4j.update_talk_count(user, t, 1)
          end
        end
      end
    end

  end
end
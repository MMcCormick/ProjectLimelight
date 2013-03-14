class PushFollowUser

  include Sidekiq::Worker
  sidekiq_options :queue => :medium_limelight

  def perform(user1_id, user2_id)
    user1 = User.find(user1_id)
    user2 = User.find(user2_id)
    user1.push_follow_user(user2) if user1 && user2
  end
end
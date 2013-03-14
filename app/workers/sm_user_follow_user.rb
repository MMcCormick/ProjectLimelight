class SmUserFollowUser

  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(user1_id, user2_id)
    user2 = User.find(user2_id)
    LlSoulmate.user_follow_user(user1_id, user2) if user2
  end
end
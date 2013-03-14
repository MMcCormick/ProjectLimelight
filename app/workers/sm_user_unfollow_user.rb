class SmUserUnfollowUser

  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(user1_id, user2_id)
    LlSoulmate.user_unfollow_user(user1_id, user2_id)
  end
end
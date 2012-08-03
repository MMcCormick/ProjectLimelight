class SmUserUnfollowUser

  @queue = :fast_limelight

  def self.perform(user1_id, user2_id)
    LlSoulmate.user_unfollow_user(user1_id, user2_id)
  end
end
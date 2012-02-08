class SmUserUnfollowUser

  @queue = :soulmate

  def self.perform(user1_id, user2_id)
    LLSoulmate.user_unfollow_user(user1_id, user2_id)
  end
end
class SmUserFollowUser

  @queue = :soulmate

  def self.perform(user1_id, user2_id)
    user2 = User.find(user2_id)
    LlSoulmate.user_follow_user(user1_id, user2) if user2
  end
end
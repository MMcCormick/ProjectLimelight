require 'json'

class FeedsUnfollowUser
  @queue = :feeds

  def self.perform(user1_id, user2_id)

    user1 = User.find(user1_id)
    user2 = User.find(user2_id)
    user1.push_unfollow_user(user1) if user1 && user2

  end

end
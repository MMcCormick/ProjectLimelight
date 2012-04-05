class AutoFollow
  @queue = :fast

  def self.perform(user_id, provider)
    user = User.find(user_id)
    user.auto_follow(provider)
  end
end
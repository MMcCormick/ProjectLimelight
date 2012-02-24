class SmDestroyUser

  @queue = :soulmate

  def self.perform(user_id)
    LlSoulmate.destroy_user(user_id)
  end
end
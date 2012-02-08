class SmDestroyUser

  @queue = :soulmate

  def self.perform(user_id)
    LLSoulmate.destroy_user(user_id)
  end
end
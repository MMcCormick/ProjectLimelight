class SmDestroyUser

  @queue = :fast_limelight

  def self.perform(user_id)
    LlSoulmate.destroy_user(user_id)
  end
end
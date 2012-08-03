class SmCreateUser

  @queue = :fast_limelight

  def self.perform(user_id)
    user = User.find(user_id)
    LlSoulmate.create_user(user) if user
  end
end
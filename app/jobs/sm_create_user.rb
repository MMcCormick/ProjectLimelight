class SmCreateUser

  @queue = :soulmate

  def self.perform(user_id)
    user = User.find(user_id)
    LLSoulmate.create_user(user) if user
  end
end
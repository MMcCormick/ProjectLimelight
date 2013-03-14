class SmCreateUser

  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(user_id)
    user = User.find(user_id)
    LlSoulmate.create_user(user) if user
  end
end
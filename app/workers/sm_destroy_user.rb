class SmDestroyUser

  include Sidekiq::Worker
  sidekiq_options :queue => :fast_limelight

  def perform(user_id)
    LlSoulmate.destroy_user(user_id)
  end
end